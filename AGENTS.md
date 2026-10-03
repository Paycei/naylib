# AGENTS.md: AI Collaboration Guide

This document provides essential context for AI models interacting with this project. Adhering to these guidelines will ensure consistency and maintain code quality.

## 1. Project Overview & Purpose

* **Fork:** This repository is a maintained fork of planetis-m/naylib (archived in August 2026). The readme's "Fork status" section records the upstream commits, the altered source notice raylib's license requires, and every change from upstream.
* **Primary Goal:** This is a Nim wrapper for raylib, a library for creating 2D and 3D games. The Nim API is designed to be user-friendly and easy to use, providing a simplified interface for raylib functions while maintaining cross-platform support.
* **Business Domain:** Game development, multimedia applications, educational tools for programming graphics.

## 2. Core Technologies & Stack

* **Languages:** Nim (version 2.0.0 or higher), C (for the underlying raylib library)
* **Frameworks & Runtimes:** Raylib (C library for game development), GLFW (for window management), OpenGL (for graphics rendering)
* **Key Libraries/Dependencies:** Raylib C source code (bundled), system libraries for graphics/audio (platform-specific)
* **Platforms:** Windows, Linux, Android, macOS, and WebAssembly (via Emscripten).
* **Package Manager:** Nimble

## 3. Architectural Patterns

* **Overall Architecture:** Language binding library that wraps the C raylib library with Nim idioms. Uses a modular approach where different aspects of raylib are exposed through separate modules (raylib.nim, raymath.nim, rlgl.nim, etc.).
* **Directory Structure Philosophy:**
    * `/src`: Contains all primary Nim source code, including the main raylib wrapper and additional modules
    * `/src/raylib`: Contains the bundled C source code for raylib
    * `/src/naylib/private`: Contains configuration options, designed to be used with Nim’s `--define:` compiler flag
    * `/tests`: Contains test files that verify functionality
    * `/docs`: Generated documentation for the Nim API
    * `/tools`: Contains tools for generating the wrapper from the Raylib API definitions
    * `/manual`: Contains detailed documentation guides and overviews
* **Module Organization:** Modules are organized to mirror the raylib library structure with raylib.nim as the core module and additional modules for specific functionality (raymath.nim, rlgl.nim, rcamera.nim, reasings.nim, rmem.nim) reside directly in the src directory rather than a nested naylib/ subdirectory.

## 4. Coding Conventions & Style Guide

* **Formatting:** Follow Nim's standard style conventions. Use 2-space indentation.
* **Naming Conventions:** 
    * Variables, procedures: camelCase (`screenWidth`, `initWindow`, `drawRectangle`)
    * Types: PascalCase (`Rectangle`, `KeyboardKey`)
    * Constants: PascalCase (`MaxShaderLocations`)
    * Enum values: CamelCase without prefix (`Left`, `Right`, `Middle` for `MouseButton`)
    * Templates/macros: camelCase (`drawing`, `mode3D`)
    * Files: snake_case for Nim files (`raylib.nim`, `raymath.nim`)
* **API Design:** 
    * Provides Nim-idiomatic wrappers around C functions
    * Uses proc overloading instead of suffixes (e.g., `drawRectangle` instead of `drawRectangle`, `drawRectangleV`, etc.)
    * Employs destructors for automatic memory management of raylib types
    * Encapsulates pointers to arrays with index operators for safe access
    * Maps C enums to Nim enums with shortened names (removing prefixes)
    * Abstracts raw pointers with `openArray[T]` and `cstring` with `string`
    * Provides syntactic sugar for begin-end pairs (templates like `drawing`)
    * Introduces `RArray[T]` type for memory-managed arrays
    * Uses `Flags[T]` type for bitflags (e.g., `ConfigFlags`, `Gesture`)
    * Provides alternatives to C functions using standard Nim libraries (e.g., `os.fileExists` instead of `FileExists`)
    * Integrates external data types with `ShaderV` and `Pixel` concepts
    * Offers `WeakImage` and `WeakWave` distinct types for embedded resources
    * Provides operator overloading for vector and matrix types (`+`, `+=`, `-`, `*`, `/`, etc.)
* **Error Handling:** 
    * Uses Nim's exception system with custom `RaylibError` exceptions for asset loading failures
    * Uses `assert` for precondition checking (e.g., ensuring window is ready before closing)
    * Implements `isValid()` checks in loading functions to prevent unexpected behavior

## 5. Key Files & Entrypoints

* **Configuration:** 
    * `src/naylib/private/config.nim` - Main configuration flags for the library
    * `naylib.nimble` - Package configuration and tasks
    * `update_bindings.nims` - Build and update tasks for the wrapper
    * `src/raylib.nim` (header): Manages all build configurations by translating the original C Makefile's settings into Nim. It is the primary reference for platform-specific compiler and linker flags, consolidating the build process into a single file.
* **CI/CD Pipeline:** `.github/workflows/ci.yml` for continuous integration

## 6. Development & Testing Workflow

* **Local Development Environment:** To set up the project locally, you need Nim installed.
    * **Install Nim**
      ```bash
      wget https://codeberg.org/janAkali/grabnim/raw/branch/master/misc/install.sh
      sh install.sh
      grabnim
      ```
    * **Setting up the project**
      1. Clone `https://github.com/Paycei/naylib` (`nimble develop naylib` would clone the archived upstream instead).
      2. Run `nimble check` to verify setup
      3. Run `nimble lock` to generate a package lock file
* **Task Configuration:** 
    * **Nimble Tasks:** Run `nimble tasks` to list all available tasks in the .nimble file, then execute with `nimble <taskname>`
    * **Custom .nims Tasks:** Tasks defined in `update_bindings.nims` can be executed with `nim <taskname> update_bindings.nims`
* **Testing:** Run tests via `nimble test`. `tests/headless_api.nim` checks wrapper behaviour without a window (run it alone with `nim c -r tests/headless_api.nim`); the other tests are examples that verify the builds. New functionality should be accompanied by appropriate tests.
* **CI/CD Process:** GitHub Actions workflow that tests on Ubuntu, Windows, and macOS for both native and WebAssembly builds. Android is not covered by CI.

## 7. Specific Instructions for AI Collaboration

* **Contribution Guidelines:**
    * Follow the existing code style and naming conventions
    * Ensure all new functionality is accompanied by appropriate tests
    * Update documentation when making changes to the API
    * Submit pull requests against the `main` branch
* **Security:**
    * Be mindful of security when handling file I/O and external resources
    * Do not hardcode secrets or keys
* **Dependencies:**
    * When adding new dependencies, edit the .nimble file and run `nimble lock`
    * Core raylib is bundled, so updates require running the update task in `update_bindings.nims` (follow `manual/update_guide.md`)
    * `src/raylib.nim`, `src/raymath.nim`, `src/rlgl.nim` and `src/rcamera.nim` are generated: edit `tools/wrapper/config/*.cfg` or `tools/wrapper/snippets/` and regenerate instead of editing them by hand
    * Any hand edit to raylib's C files in `src/raylib/` must be added to the altered source notice in `readme.md` (raylib's zlib license requires it)
* **Versioning:** `<raylib major>.<raylib minor>.<patch>` (see Versioning in `readme.md`). A raylib update that changes the major or minor version resets the patch to 0; any other release raises it. Keep `version` in `naylib.nimble` in step.
* **Commit Messages:** Follow conventional commit messages with clear, descriptive summaries of changes
