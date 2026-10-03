# Updating raylib and Nim Wrappers

This guide describes the process of updating the bundled raylib version and regenerating the Nim wrappers.
Run every command from the repository root (also when it is checked out as a submodule of another project). On Windows use Git Bash, so the shell snippets below work as written.

## Prerequisites

- `git`, and a C compiler on `PATH` as `cc` (MinGW provides one on Windows).
- The `eminim` 2.8.2 package, used by the wrapper generator: `nimble install eminim@2.8.2`.
- `unifdef`, for Step 2. Linux distributions package it. On Windows, build it from
  [fanf2/unifdef](https://github.com/fanf2/unifdef) and put the folder on `PATH`:

  ```bash
  git clone --depth 1 https://github.com/fanf2/unifdef.git && cd unifdef
  echo '"@(#) $Version: unifdef-git $\n"' > version.h
  cd win32 && cp ../unifdef.c ../version.h .
  # gnu99: newer compilers default to C23, where unifdef's `constexpr` identifier is a keyword
  cc -std=gnu99 -O2 -I. -o ../unifdef.exe unifdef.c win32.c ../FreeBSD/getopt.c ../FreeBSD/err.c
  ```

## Step 1: Update raylib source

1. Edit `update_bindings.nims`:
   - Update the `RayLatestCommit` constant to the desired raylib commit hash

2. Run the update task:
   ```bash
   nim update update_bindings.nims
   ```
   This fetches the specified raylib version in `raylib/` (a git repository tracking raysan5/raylib, ignored by git) and copies the sources to `src/raylib/`

3. Build the parser, mangler and wrapper tools:
   ```bash
   nim buildTools update_bindings.nims
   ```

## Step 2: Resolve identifier conflicts

Some C symbols in raylib conflict with each other. To fix these clashes:

1. **Run the mangling script**

   ```bash
   nim mangle update_bindings.nims
   ```

   This modifies the raylib C source files in `src/raylib/` (the bundled sources), renaming symbols that would otherwise cause collisions.
   If the mangler's rename list changes, update the altered source notice in `readme.md`.

2. **Manually adjust `rlgl` header**
   The API generator cannot correctly process `#if defined` conditional sections in `rlgl.h`. You must preprocess the file in `raylib/src/` manually:

   ```bash
   (cd raylib && echo "" >> src/rlgl.h && { unifdef -UGRAPHICS_API_OPENGL_ES2 -DGRAPHICS_API_OPENGL_33 src/rlgl.h > src/rlgl.h.tmp || [ $? -le 1 ]; } && mv -f src/rlgl.h.tmp src/rlgl.h)
   ```

   Check that it printed no error: if `unifdef` is missing, the snippet stops before replacing the header, and Step 3 then produces a wrong `rlgl.json` without complaining.

## Step 3: Update API JSON definitions

1. Generate new JSON definitions:
   ```bash
   nim genApi update_bindings.nims
   ```
   This creates updated JSON files in `tools/wrapper/api/` for raylib, rcamera, raymath, and rlgl.

## Step 4: Update Nim wrappers

1. **CRITICAL STEP**: Before generating wrappers, read `manual/review_guide.md` and follow its steps carefully!
2. Generate updated Nim wrappers:
   ```bash
   nim genWrappers update_bindings.nims
   ```
   This creates updated `.nim` files in `src/` based on the new JSON definitions and configuration files.

## Step 5: Update documentation

Generate updated HTML documentation:
```bash
nim docs update_bindings.nims
```

## Step 6: Verify changes

1. Run the wrapper tests:
   ```bash
   nim c -r tests/headless_api.nim
   nim c -r tests/basic_window.nim
   ```

2. Build a real project against the new bindings (as a submodule, check out the new commit there): every changed signature shows up as a compile error at its call sites. `nim check` finds them all without producing a binary.

3. raylib can change behaviour without changing a signature (raylib 6 moved thick outlines inside their shapes, for example). Compare that project's text measurements and screenshots of its shapes against the previous naylib commit before trusting the update.

4. Update `readme.md`: the raylib commit under Fork status, and anything new under Changes from upstream naylib.

5. Set `version` in `naylib.nimble` (see Versioning in `readme.md`): `<major>.<minor>.0` when the raylib major or minor version changed (compare `RaylibVersion` in `src/raylib.nim`), otherwise raise the patch number. Release by pushing a `v<version>` tag.
