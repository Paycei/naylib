# Naylib

<img src="assets/naylib.png" alt="Naylib logo" width="15%" />

> **This is a maintained fork of [planetis-m/naylib](https://github.com/planetis-m/naylib)**,
> which was archived in August 2026. Version 6.1.0 bundles raylib `987a0e54` (6.1-dev).
> See [Fork status](#fork-status) for where it comes from and what changed, and
> [Versioning](#versioning) for what the version number means.

Welcome to this repository! Here you'll find a Nim wrapper for raylib, a library for
creating 2D and 3D games. The Nim API is designed to be user-friendly and easy to use.

## Features

- **Easy-to-use API**: Simplified Nim interface for raylib functions
- **Cross-platform support**: Develop for multiple platforms including Windows, Linux, macOS, Web and Android
- **Comprehensive documentation**: Detailed guides and API references
- **Active community**: Get support and share your creations

## Documentation

To learn more about how to use this wrapper, you can check out the documentation:

- [raylib](https://paycei.github.io/naylib/raylib.html) - Core library for videogame programming
- [raymath](https://paycei.github.io/naylib/raymath.html) - Mathematical functions for game development
- [rlgl](https://paycei.github.io/naylib/rlgl.html) - Abstraction layer for OpenGL with immediate-mode API
- [reasings](https://paycei.github.io/naylib/reasings.html) - Smooth animation transitions
- [rmem](https://paycei.github.io/naylib/rmem.html) - Memory pool and objects pool allocators
- [rcamera](https://paycei.github.io/naylib/rcamera.html) - Basic camera system
- raygui - Offered as a separate package: [naygui](https://github.com/planetis-m/naygui)

If you're familiar with the C version of raylib, you may find the
[cheatsheet](https://www.raylib.com/cheatsheet/cheatsheet.html) useful. When porting C code to Nim, also refer to the [raylib translation guide](https://github.com/planetis-m/raylib-examples/blob/main/raylib_translation_guide.md)

## Installation

`nimble install naylib` installs the archived upstream release, not this fork. Use one of these instead:

- **As a git submodule** (pins an exact commit per project):

  ```bash
  git submodule add https://github.com/Paycei/naylib.git vendor/naylib
  ```

  Then add the bindings to the project's `config.nims`:

  ```nim
  switch("path", thisDir() & "/vendor/naylib/src")
  ```

  Put it after any other `--path`: the last one wins, so a naylib installed by Nimble can't
  shadow it. Clones of the project then need `git clone --recursive`, or
  `git submodule update --init` in an existing clone.

- **With Nimble**: `nimble install https://github.com/Paycei/naylib`

  Require it by URL in a `.nimble` file too. A version range alone can be met by an upstream
  release: upstream's last one is 26.08.0, which Nimble ranks above every version of this fork.

For Linux users only: Ensure you have the [required](https://github.com/raysan5/raylib/wiki/Working-on-GNU-Linux)
dependencies installed using your distribution's native package manager.

## Examples

We've also provided some example code to help you get started. You can find it in the
accompanying [example repository](https://github.com/planetis-m/raylib-examples).
To compile and run an example: `nim c -r -d:release example.nim`

## Changes from Raylib to Naylib

Naylib introduces several improvements and changes compared to the original Raylib.
For a comprehensive overview of these changes, including memory management, naming
conventions, and API improvements, please refer to our
[Changes Overview](manual/changes_overview.md) document.

## Usage Guides

### Advanced Usage Guide

* [Advanced Usage Guide](manual/advanced_usage.md)
**What's inside:**
* **RAII & Destructors:** Understanding how Naylib automates `Unload*` functions using Nim's memory model.
* **Ownership Rules:** How to handle textures, meshes, and models without accidental double-frees or leaks.
* **Window Lifecycle:** Proper usage of `initWindow` and `closeWindow` with `defer` or owning objects.
* **Optimization:** Using "Weak Views" for embedded resources and custom pixel formats for external data.
* **Math Integration:** How to bridge Naylib with external math libraries like `vmath` or `glm`.

### Build & Platform Configuration Guide

Covers compilation flags, platform targets, graphics backends, and deployment.

- [Build & Platform Configuration Guide](manual/build_platform_configuration.md)
- [Changing raylib settings with Nim defines](manual/build_platform_configuration.md#changing-raylib-settings-with-nim-defines)
- [Building for the Web (WebAssembly)](manual/build_platform_configuration.md#building-for-the-web-webassembly)
- [Building for Android](manual/build_platform_configuration.md#building-for-android)
- [Choosing the OpenGL graphics backend](manual/build_platform_configuration.md#choosing-the-opengl-graphics-backend-version)

### Development Guides

For contributors and maintainers:

- [Update Guide](manual/update_guide.md) - Step-by-step process for updating the raylib version and regenerating wrappers
- [Configuration Guide](manual/config_guide.md) - Detailed information on configuration options for the wrapper generator
- [Review Guide](manual/review_guide.md) - How to identify and implement configuration changes when updating raylib
- [Tooling](tooling.md) - The parser, mangler and wrapper generator, and the tasks in `update_bindings.nims`

`src/raylib.nim`, `src/raymath.nim`, `src/rlgl.nim` and `src/rcamera.nim` are generated: change
`tools/wrapper/config/*.cfg` or `tools/wrapper/snippets/`, then regenerate them as the Update
Guide describes. `src/reasings.nim`, `src/rmem.nim` and `src/naylib/private/config.nim` are
written by hand.

Tests:

```bash
nimble test                       # what CI runs: the wrapper checks, then native and web builds
nim c -r tests/headless_api.nim   # wrapper checks only, no window
nim c -r tests/basic_window.nim   # opens a window
```

## Platform Support

| Target           | Windows           | Linux             | macOS             |
|------------------|-------------------|-------------------|-------------------|
| Native           | Supported, Tested | Supported, Tested | Supported, Tested |
| WebAssembly      | Supported, Tested | Supported, Tested | Supported, Tested |
| DRM              | N/A               | Supported         | N/A               |
| Android          | Supported         | Supported         | Possibly Works    |
| Windows (Cross)  | N/A               | Supported, Tested | Untested          |

### Development Status

- The CI pipeline builds on Windows, Linux, and macOS, for both native and WebAssembly targets.
- Android builds are not covered by this fork's CI.

### CI Status

[![Native & WebAssembly CI](https://img.shields.io/github/actions/workflow/status/Paycei/naylib/ci.yml?branch=main&label=Native%20%26%20WebAssembly%20CI)](https://github.com/Paycei/naylib/actions/workflows/ci.yml)

## Versioning

Versions are `<raylib major>.<raylib minor>.<patch>`. The first two numbers are the bundled
raylib version (`RaylibVersion` in `src/raylib.nim`), and the patch counts this library's
releases on that raylib version, starting at 0: 6.1.0 is the first release on raylib 6.1,
6.1.1 the next one, and moving to raylib 6.2 starts again at 6.2.0. Each release is a `v<version>`
tag (for example `v6.1.0`), which publishes a GitHub release.

raylib `987a0e54` is a development snapshot of 6.1 ("6.1-dev"), so the 6.1 releases follow it
until raylib 6.1 itself is released. Upstream naylib used calendar versions (26.08.0 was its last).

## Fork status

### Origin

- **naylib**: planetis-m/naylib `main` at `a48d407` (v26.08.0 plus two commits, the final
  upstream state). MIT, see [LICENSE](LICENSE).
- **raylib**: [raysan5/raylib](https://github.com/raysan5/raylib) at `987a0e54` (6.0 plus
  about 450 commits, "6.1-dev"). zlib/libpng, see [LICENSE-RAYLIB](LICENSE-RAYLIB). The commit
  is `RayLatestCommit` in `update_bindings.nims`.

### Altered source notice (raylib license, clause 2)

`src/raylib/` is not the original raylib source. It is raylib's `src/` after naylib's mangler
(`tools/mangler/naylib_mangler.nim`), which renames identifiers that clash with `windows.h` by
prefixing them with `rl`: `Rectangle`, `CloseWindow`, `ShowCursor`, `LoadImage`, `DrawText`,
`DrawTextEx`. At raylib `987a0e54` that is the only difference from upstream raylib. Any other
change made to raylib's C files here must be listed in this section.

### Changes from upstream naylib

- raylib updated from `afe74c1c` (5.6-dev) to `987a0e54`, wrappers regenerated. API changes
  picked up: the model animation rework (`Model.skeleton`, `currentPose`, `boneMatrices`;
  `ModelAnimation.keyframeCount`/`keyframePoses`; `Mesh.boneIndices`; `updateModelAnimation`
  takes a float frame and gains a blending overload), thickness overloads for the line
  shapes, the new `imageDraw*` family, `loadRenderTexture` with a format, `drawTriangleGradient`,
  `measureTextCodepoints`, rlgl shader loading from code strings, and `drawCircleGradient`
  taking a `Vector2` centre.
- Behaviour changes in raylib to watch for when porting: a positive `thick` in the
  `Draw*LinesEx` family (e.g. the 5-argument `drawRectangleRoundedLines`) now strokes inside the
  shape and a negative one outside, and `drawMesh` never uploads bone matrices (only `drawModel*`
  does).
- `naylib/private/config.nim` mirrors raylib's new `config.h`: GPU skinning is
  `NaylibSupportGpuSkinning`, off by default as upstream (upstream naylib had it on), PNM/PEP
  formats added. macOS links QuartzCore and Android links with `--wrap=fopen`, both now
  required by raylib. `raylibDir` is defined after the MinGW path override.
- `DefaultShaderLocationIndex` order fixed to match `rlgl.h`; instance transform attribute added.
- Fixes in hand-written wrapper code: `RArray` copy hooks allocated `len` bytes instead of
  `len * sizeof(T)` (heap overflow); the trace log callback formatted into a 128-byte buffer
  with `vsprintf` (now a bounded `vsnprintf` that keeps truncated text, also on pre-C99
  runtimes); `updateSound`/`updateAudioStream` passed the element count as the frame count;
  file IO callback types now match raylib's C signatures; `exportDataAsCode` produced an
  invalid identifier and crashed on empty input; `rmem` exact-fit `MemPool` allocations were
  not marked used and `BiStack` back allocations were misplaced. `tests/headless_api.nim`
  covers these, and `nimble test` runs it.
- Tooling: `update_bindings.nims` builds its tools and the docs with `--skipParentCfg` (when
  this repo is a submodule, the parent project's `config.nims` would otherwise apply to them)
  and runs the tools by absolute path (a bare name does not launch on Windows). The Update
  Guide lists every prerequisite, including how to build `unifdef` on Windows. CI runs on
  `main`.

## Alternative Game Development Libraries

While we believe that Naylib provides a great option for game development with Nim, we understand
that it may not be the perfect fit for everyone. Here are some noteworthy alternatives:

- [NimForUE](https://github.com/jmgomez/NimForUE): Plugin for Unreal Engine 5
- [nim-sdl3](https://github.com/dinau/sdl3_nim): Nim wrapper for SDL3.x
- [sokol-nim](https://github.com/floooh/sokol-nim): Auto-generated bindings for sokol headers
- [gdextcore](https://github.com/godot-nim/gdext-nim): Godot 4.x bindings
- [norx](https://github.com/tankfeud/norx): Nim wrapper for the ORX 2.5D game engine
- [godot-nim](https://github.com/pragmagic/godot-nim): Godot 3 bindings
- [nico](https://github.com/ftsf/nico): Pico-8 inspired game framework
- [p5nim](https://github.com/pietroppeter/p5nim): Processing library

For a comprehensive list of game development resources in Nim,
visit [awesome-nim](https://github.com/ringabout/awesome-nim#game-development).

## Contributing

Bug reports, feature requests and pull requests are welcome on this repository.

## License

Naylib is open-source software licensed under the [MIT](LICENSE) License.

Please note that the raylib [source](src/raylib) code included in this distribution is licensed under
the [zlib](LICENSE-RAYLIB) license, and is altered as described in the
[altered source notice](#altered-source-notice-raylib-license-clause-2).

## Contact

For support and discussions about raylib in Nim:
- Nim server (#gamedev): [discord.gg/nim](https://discord.gg/nim)
- Raylib server (#raylib-nim): [discord.gg/raylib](https://discord.gg/raylib)
