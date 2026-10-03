import std/[os, strutils]

const
  ProjectUrl = "https://github.com/Paycei/naylib"
  PkgDir = thisDir()
  RaylibDir = PkgDir / "raylib"   # git checkout of raysan5/raylib (ignored), not src/raylib
  RaylibGit = "https://github.com/raysan5/raylib.git"
  RayLatestCommit = "987a0e54c7ab1bdab459989b319a9064bb088b69"
  DocsDir = PkgDir / "docs"
  ToolsDir = PkgDir / "tools"
  ApiDir = ToolsDir / "wrapper/api"
  # The tools are standalone programs: when this repo is a git submodule, keep
  # the parent project's config.nims (a --noNimblePath there hides eminim) out
  # of their builds.
  ToolFlags = "--skipParentCfg --mm:arc --panics:on -d:release"

proc tool(dir, name: string): string =
  ## A built tool by absolute path: a bare name does not launch on Windows.
  quoteShell(ToolsDir / dir / toExe(name))

proc fetchLatestRaylib() =
  var firstTime = false
  if not dirExists(RaylibDir):
    firstTime = true
    exec "git clone --depth 1 " & RaylibGit & " " & quoteShell(RaylibDir)
  withDir(RaylibDir):
    if not firstTime:
      exec "git restore ."
      exec "git switch - --detach"
    exec "git fetch --depth 200 origin " & RayLatestCommit
    exec "git checkout " & RayLatestCommit

proc buildParser() =
  withDir(ToolsDir / "parser"):
    let src = "raylib_parser.c"
    let exe = toExe("raylib_parser")
    # if not fileExists(exe) or fileNewer(src, exe):
    exec "cc " & src & " -o " & exe

proc buildMangler() =
  withDir(ToolsDir / "mangler"):
    let src = "naylib_mangler.nim"
    let exe = toExe("naylib_mangler")
    # if not fileExists(exe) or fileNewer(src, exe):
    exec "nim c " & ToolFlags & " " & src

proc buildWrapper() =
  withDir(ToolsDir / "wrapper"):
    let src = "naylib_wrapper.nim"
    let exe = toExe("naylib_wrapper")
    # if not fileExists(exe) or fileNewer(src, exe):
    exec "nim c " & ToolFlags & " -d:emiLenient " & src

proc genApiJson(lib, prefix, after: string) =
  withDir(ToolsDir / "parser"):
    mkDir(ApiDir)
    let header = RaylibDir / "src" / (lib & ".h")
    let apiJson = ApiDir / (lib & ".json")
    let prefixArg = if prefix != "": "-d " & prefix else: ""
    exec tool("parser", "raylib_parser") & " -f JSON " & prefixArg & " -i " & header.quoteShell &
        " -t " & after.quoteShell & " -o " & apiJson.quoteShell

proc genWrapper(lib: string) =
  withDir(ToolsDir / "wrapper"):
    let outp = PkgDir / "src" / (lib & ".nim")
    let conf = "config" / (lib & ".cfg")
    exec tool("wrapper", "naylib_wrapper") & " -c:" & conf & " -o:" & outp

proc wrapRaylib(lib, prefix, after: string) =
  genApiJson(lib, prefix, after)
  genWrapper(lib)

task buildTools, "Build raylib_parser and naylib_wrapper":
  buildParser()
  buildWrapper()
  buildMangler()

task genApi, "Generate API JSON files":
  buildParser()
  genApiJson("raylib", "RLAPI", "")
  genApiJson("rcamera", "RLAPI", "#endif // RCAMERA_H")
  genApiJson("raymath", "RMAPI", "")
  genApiJson("rlgl", "", "#endif // RLGL_H")

task genWrappers, "Generate Nim wrappers":
  genWrapper("raylib")
  genWrapper("rcamera")
  genWrapper("raymath")
  genWrapper("rlgl")

task update, "Update the raylib git directory":
  fetchLatestRaylib()
  rmDir(PkgDir / "src/raylib")
  cpDir(RaylibDir / "src", PkgDir / "src/raylib")
  cpFile(RaylibDir / "tools/rlparser/rlparser.c", ToolsDir / "parser/raylib_parser.c")

task mangle, "Mangle identifiers in raylib source":
  buildMangler()
  withDir(ToolsDir / "mangler"):
    exec tool("mangler", "naylib_mangler") & " " & quoteShell(PkgDir / "src/raylib")

task wrap, "Produce all raylib Nim wrappers":
  buildToolsTask()
  wrapRaylib("raylib", "RLAPI", "")
  wrapRaylib("rcamera", "RLAPI", "#endif // RCAMERA_H")
  wrapRaylib("raymath", "RMAPI", "")
  wrapRaylib("rlgl", "", "#endif // RLGL_H")

task docs, "Generate documentation":
  withDir(PkgDir):
    for tmp in ["raymath", "raylib", "rlgl", "reasings", "rmem", "rcamera"]:
      let doc = DocsDir / (tmp & ".html")
      let src = "src" / tmp
      let showNonExports = if tmp != "rmem": " --shownonexports" else: ""
      exec "nim doc --skipParentCfg --verbosity:0 --git.url:" & ProjectUrl & showNonExports &
           " --git.devel:main --git.commit:main --out:" & doc.quoteShell & " " & src
