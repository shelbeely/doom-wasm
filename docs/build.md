# Build System

## Prerequisites

Install once (macOS; adapt for Linux):

```bash
brew install emscripten automake
brew install sdl2 sdl2_mixer sdl2_net
```

## Compile

```bash
./scripts/build.sh
```

Internally runs:

```bash
emmake make clean
emconfigure autoreconf -fiv
ac_cv_exeext=".html" emconfigure ./configure --host=none-none-none
emmake make
```

## Key Emscripten Flags (`configure.ac` → `EMFLAGS`)

| Flag | Purpose |
|------|---------|
| `-s WASM=1` | Emit WebAssembly |
| `-s USE_SDL=2` / `USE_SDL_MIXER=2` / `USE_SDL_NET=2` | Emscripten SDL ports |
| `-s ASYNCIFY` | Allow `emscripten_sleep` / blocking-style async |
| `-s EXPORTED_RUNTIME_METHODS=[['FS','ccall']]` | Expose FS and ccall to JS |
| `-s TOTAL_MEMORY=64MB` | Fixed heap — growth is disabled |
| `-s FORCE_FILESYSTEM=1` | Virtual FS needed for WAD loading |
| `-lwebsocket.js` | Emscripten WebSockets library |

Flags live in `configure.ac`. Adding or removing a flag requires updating this file
and rebuilding from scratch with `./scripts/clean.sh && ./scripts/build.sh`.

## Clean

```bash
./scripts/clean.sh
```

Removes all Autotools and Emscripten-generated artefacts.  Run before a clean build.

## Run Locally

```bash
cp /path/to/doom1.wad src/
cd src
python3 -m http.server
# open http://0.0.0.0:8000/
```

`doom1.wad` is gitignored and must never be committed.  The shareware version is
freely available at https://doomwiki.org/wiki/DOOM1.WAD.

## CI

There is **no** automated compile/test CI for the Wasm build (it requires Emscripten).
The only automated workflow is Semgrep static analysis (`.github/workflows/semgrep.yml`).
After any C source change, run `./scripts/build.sh` locally to verify.
