# ****************************************************************************************
#
#   Headless API checks
#
#   Exercises parts of the wrapper that do not require a window or GPU context,
#   so they can run in CI: CPU image drawing, RArray memory management, and the
#   trace log and file IO callbacks. Model animation accessors, which need loaded
#   GPU resources, are type-checked only.
#
# ****************************************************************************************

import raylib, raymath, rmem, std/[os, strutils, unicode]

# ----------------------------------------------------------------------------------------
# Trace log callback
# ----------------------------------------------------------------------------------------

var lastLog = ""

proc logger(logLevel: TraceLogLevel; text: string) =
  lastLog = text

proc testTraceLogCallback() =
  setTraceLogCallback(logger)
  traceLog(Info, "value: %d", 42'i32)
  doAssert lastLog == "value: 42", lastLog
  # Long messages are truncated instead of overflowing the formatting buffer
  let long = repeat('x', 1000)
  traceLog(Info, "%s", long.cstring)
  doAssert lastLog.len == 256
  doAssert lastLog == long[0..255]

# ----------------------------------------------------------------------------------------
# File IO callbacks
# ----------------------------------------------------------------------------------------

var savedBytes = 0'i32
var loadRequested = false

proc saveData(fileName: cstring; data: pointer; dataSize: int32): bool {.cdecl.} =
  savedBytes = dataSize
  result = data != nil

proc loadData(fileName: cstring; dataSize: ptr int32): ptr UncheckedArray[uint8] {.cdecl.} =
  loadRequested = true
  dataSize[] = 0
  result = nil

proc testFileDataCallbacks() =
  setSaveFileDataCallback(saveData)
  setLoadFileDataCallback(loadData)
  let image = genImageColor(8, 8, Red)
  doAssert exportImage(image, "callback.png")
  doAssert savedBytes > 0
  doAssertRaises(RaylibError):
    discard loadImage("callback.png")
  doAssert loadRequested
  setSaveFileDataCallback(nil)
  setLoadFileDataCallback(nil)

# ----------------------------------------------------------------------------------------
# RArray memory management
# ----------------------------------------------------------------------------------------

proc testRArray() =
  var image = genImageColor(16, 16, Red)
  imageDrawPixel(image, 0, 0, Blue)
  let colors = loadImageColors(image)
  doAssert colors.len == 256
  doAssert colors[0] == Blue and colors[255] == Red
  # =dup
  var copy = colors
  copy[1] = Green
  doAssert colors[1] == Red and copy[1] == Green
  doAssert copy[0] == Blue and copy[255] == Red
  # =copy
  var assigned: RArray[Color]
  assigned = colors
  doAssert assigned.len == colors.len and assigned[255] == Red
  # Conversion to seq and openArray
  let s = @colors
  doAssert s.len == 256 and s[0] == Blue and s[255] == Red
  doAssert @(toOpenArray(colors, 0, 3)) == @[Blue, Red, Red, Red]
  doAssert toOpenArray(colors).len == 256

# ----------------------------------------------------------------------------------------
# CPU image drawing
# ----------------------------------------------------------------------------------------

proc testImageDrawing() =
  var dst = genImageColor(64, 64, Black)
  let src = genImageColor(8, 8, White)
  imageDrawImage(dst, src, 0, 0, White)
  doAssert getImageColor(dst, 1, 1) == White
  imageDrawImage(dst, src, Rectangle(x: 0, y: 0, width: 8, height: 8),
      Rectangle(x: 16, y: 16, width: 16, height: 16), Vector2(), 0, White)
  doAssert getImageColor(dst, 30, 30) == White
  imageDrawImage(dst, src, Rectangle(x: 0, y: 0, width: 4, height: 4), Vector2(x: 40, y: 0), White)
  doAssert getImageColor(dst, 42, 2) == White
  imageDrawImage(dst, src, Vector2(x: 40, y: 40), 0, 0.5, White)
  imageDrawLineStrip(dst, [Vector2(x: 0, y: 60), Vector2(x: 63, y: 60)], Red)
  doAssert getImageColor(dst, 32, 60) == Red
  imageDrawLineStrip(dst, [], Red)
  imageDrawRectangleLines(dst, 0, 50, 10, 5, Green)
  imageDrawRectangleLines(dst, Rectangle(x: 20, y: 50, width: 10, height: 5), 1, Green)
  imageDrawRectangle(dst, Rectangle(x: 50, y: 10, width: 8, height: 8), Vector2(), 0, Blue)
  doAssert getImageColor(dst, 52, 12) == Blue
  imageDrawRectangleGradient(dst, Rectangle(x: 0, y: 20, width: 8, height: 8), Red, Green, Blue, White)
  imageDrawCircleGradient(dst, Vector2(x: 32, y: 32), 4, White, Black)
  imageDrawTriangleGradient(dst, Vector2(x: 0, y: 0), Vector2(x: 0, y: 8), Vector2(x: 8, y: 0),
      Red, Green, Blue)
  imageColorContrast(dst, 10)

proc testExportDataAsCode() =
  let path = getTempDir() / "naylib-test-data.nim"
  doAssert exportDataAsCode([0x01'u8, 0xAB, 0xFF], path)
  let code = readFile(path)
  removeFile(path)
  doAssert "const naylibTestDataData: array[3, byte] = [\n  0x01, 0xAB, 0xFF ]\n" in code, code
  doAssert exportDataAsCode([], path)
  doAssert "const naylibTestDataData: array[0, byte] = [ ]" in readFile(path)
  removeFile(path)

proc testRmem() =
  var buffer {.align(64).}: array[1024, byte]
  # An allocation that consumes a whole free block must still be tracked
  var mp = createMemPool(buffer)
  let capacity = mp.getFreeMemory()
  let p = mp.alloc(capacity - 4*sizeof(pointer))
  doAssert p != nil and mp.getFreeMemory() == 0
  mp.free(p)
  doAssert mp.getFreeMemory() == capacity
  # Back allocations come from the end of the buffer and never overlap the front
  var bs = createBiStack(buffer)
  let base = cast[uint](addr buffer[0])
  let front = bs.allocFront(8)
  let back = bs.allocBack(8)
  doAssert cast[uint](front) == base
  doAssert cast[uint](back) >= base + uint(buffer.len - 16)
  doAssert bs.margins() >= 0
  doAssert bs.allocBack(buffer.len) == nil
  bs.resetAll()
  doAssert bs.margins() == buffer.len

proc testRaymath() =
  let m = Matrix.identity * 2'f32
  doAssert m.m0 == 2 and m.m5 == 2 and m.m15 == 2
  var n = Matrix.identity
  n *= 3'f32
  doAssert n.m10 == 3
  doAssert getSplinePointBezierQuadratic(Vector2(), Vector2(x: 1, y: 1), Vector2(x: 2, y: 0), 0) == Vector2()

# ----------------------------------------------------------------------------------------
# Compile-only checks for APIs that require a GPU context
# ----------------------------------------------------------------------------------------

proc compileOnlyModelApi(model: var Model, anims: RArray[ModelAnimation], mesh: var Mesh) {.used.} =
  let anim = anims[0]
  if isModelAnimationValid(model, anim):
    updateModelAnimation(model, anim, 1.5)
    updateModelAnimation(model, anim, 0, anims[anims.len - 1], 2, 0.5)
  for i in 0..<model.skeleton.boneCount.int:
    discard model.skeleton.bones[i].parent
    model.skeleton.bindPose[i] = model.currentPose[i]
    discard model.boneMatrices[i]
  for f in 0..<anim.keyframeCount:
    for b in 0..<anim.boneCount.int:
      discard anim.keyframePoses[f, b]
  for i in 0..<mesh.vertexCount:
    discard mesh.boneIndices[i]
    discard mesh.boneWeights[i]
  discard mesh.vboId[MaxMeshVertexBuffers - 1]

proc compileOnlyDrawApi(font: Font) {.used.} =
  let target = loadRenderTexture(64, 64, UncompressedR32g32b32a32)
  drawTriangleGradient(Vector2(), Vector2(x: 0, y: 1), Vector2(x: 1, y: 0), Red, Green, Blue)
  drawTriangleLines(Vector2(), Vector2(x: 0, y: 1), Vector2(x: 1, y: 0), 2, Red)
  drawCircleLines(Vector2(), 10, 2, Red)
  drawCircleSectorLines(Vector2(), 10, 0, 90, 8, 2, Red)
  drawCircleGradient(Vector2(), 10, White, Black)
  drawEllipseLines(Vector2(), 10, 5, 2, Red)
  drawRingLines(Vector2(), 5, 10, 0, 360, 16, 2, Red)
  drawTexture(target.texture, Rectangle(), Vector2(), White)
  discard measureTextCodepoints(font, [Rune('a'), Rune('b')], 10, 1)

# ----------------------------------------------------------------------------------------
# Program main entry point
# ----------------------------------------------------------------------------------------

proc main =
  setTraceLogLevel(Info)
  testTraceLogCallback()
  testFileDataCallbacks()
  testRArray()
  testImageDrawing()
  testRaymath()
  testRmem()
  testExportDataAsCode()
  echo "All headless API checks passed"

main()
