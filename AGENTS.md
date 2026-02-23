# AGENTS.md

This file is the authoritative guide for AI coding agents working in this repository.
It describes the project, directory layout, how to build and test, architectural rules,
and the conventions you must follow when making changes.

---

## Project Overview

**Wasm Doom** is a [Chocolate Doom](https://github.com/chocolate-doom/chocolate-doom)
WebAssembly port with real-time WebSockets multiplayer support.  It is compiled with
[Emscripten](https://emscripten.org/) and runs in a browser.  The networking layer
replaces SDL_net with a custom WebSockets module (`src/net_websockets.c`) so that the
game can reach a cloudflare-worker relay server (`doom-workers`).

The build output is a set of browser-deployable files (`.html`, `.js`, `.wasm`) served
from `src/` with a simple static HTTP server.

---

## Repository Layout

```
doom-wasm/
├── AGENTS.md           ← this file
├── README.md           ← human-readable getting-started guide
├── configure.ac        ← Autotools build configuration (Emscripten flags live here)
├── Makefile.am         ← top-level Automake file
├── CMakeLists.txt      ← CMake build (not used for the Wasm target)
├── scripts/
│   ├── build.sh        ← full clean-configure-make cycle via Emscripten
│   └── clean.sh        ← removes all generated build artefacts
├── src/                ← main game source (C)
│   ├── index.html      ← browser entry point; loads websockets-doom.js
│   ├── net_websockets.c/h  ← WebSockets network backend (Emscripten-specific)
│   ├── debug.h         ← lightweight debug-print macro (LDEBUG flag)
│   ├── doom/           ← Doom-specific game logic (d_main.c, g_game.c, …)
│   └── …               ← shared Chocolate Doom sources
├── tests/
│   ├── common.h
│   ├── pthreads.c      ← pthread smoke-test (Emscripten pthreads)
│   └── websockets_client.c ← WebSocket echo client smoke-test
├── opl/                ← OPL synthesiser library
├── pcsound/            ← PC speaker sound library
├── textscreen/         ← text-mode UI library
└── data/               ← game data helpers
```

---

## Build System

The Wasm target uses **Autotools + Emscripten**.  CMake is present for native builds
but is **not** used for the browser/Wasm target.

### Prerequisites

Install these once (macOS example; adapt for Linux):

```bash
brew install emscripten automake
brew install sdl2 sdl2_mixer sdl2_net
```

### Compile

```bash
./scripts/build.sh
```

Internally this runs:

```bash
emmake make clean
emconfigure autoreconf -fiv
ac_cv_exeext=".html" emconfigure ./configure --host=none-none-none
emmake make
```

Key Emscripten flags (defined in `configure.ac` as `EMFLAGS`):

| Flag | Purpose |
|------|---------|
| `-s WASM=1` | Emit WebAssembly |
| `-s USE_SDL=2` / `USE_SDL_MIXER=2` / `USE_SDL_NET=2` | Emscripten SDL ports |
| `-s ASYNCIFY` | Allow `emscripten_sleep` / blocking-style async |
| `-s EXPORTED_RUNTIME_METHODS=[['FS','ccall']]` | Expose FS and ccall to JS |
| `-s TOTAL_MEMORY=64MB` | Fixed heap (no growth) |
| `-s FORCE_FILESYSTEM=1` | Virtual FS needed for WAD loading |
| `-lwebsocket.js` | Emscripten WebSockets library |

### Clean

```bash
./scripts/clean.sh
```

### Run locally

```bash
cp /path/to/doom1.wad src/
cd src
python3 -m http.server
# open http://0.0.0.0:8000/
```

---

## Architecture & Module Boundaries

1. **Networking (`src/net_websockets.c`)** — The only network backend for the Wasm
   build.  It speaks a simple framing protocol over a binary WebSocket connection:
   bytes 0–3 are a little-endian `uint32_t` source IP, the remainder is a
   `net_packet_t` payload.  Do **not** add SDL_net calls here; this module replaces it.

2. **stdout protocol** — Important runtime events are communicated to the host web page
   via numbered `printf` messages on stdout.  The JavaScript in `src/index.html`
   captures `Module.print` and can parse these.  **Never change the numeric codes**
   without updating both the C source and `README.md`.

   | Code | Meaning | Source file |
   |------|---------|-------------|
   | `doom: 1` | failed to connect to WebSockets server | `net_websockets.c` |
   | `doom: 2` | connected to `<url>` | `net_websockets.c` |
   | `doom: 3` | out of client addresses | `net_websockets.c` |
   | `doom: 4` | ws error | `net_websockets.c` |
   | `doom: 5` | ws close | `net_websockets.c` |
   | `doom: 6` | failed to send ws packet, reconnecting | `net_websockets.c` |
   | `doom: 7` | failed to connect to `<addr>` | `d_loop.c` |
   | `doom: 8` | uid is `<n>` | `d_loop.c` |
   | `doom: 9` | disconnected from server | `d_loop.c` |
   | `doom: 10` | game started | `doom/d_net.c` |
   | `doom: 11` | entering fullscreen | `doom/g_game.c` |
   | `doom: 12` | client `<name>` timed out and disconnected | `net_server.c` |

3. **Packet queue (`net_websockets.c`)** — A fixed-size circular buffer of
   `MAX_QUEUE_SIZE` (64) entries.  If the queue is full, incoming packets are silently
   dropped.  Keep this behaviour unless you also update queue-full handling.

4. **Debug logging (`src/debug.h`)** — Guarded by `#define LDEBUG`.  When `LDEBUG` is
   `0` (default) all `D(x)` calls compile to nothing.  Do not add unconditional
   `printf` calls to hot paths.

5. **Browser entry point (`src/index.html`)** — Loads `websockets-doom.js` and passes
   `commonArgs` to `callMain`.  The canvas element **must not** have CSS border or
   padding or mouse coordinates will be wrong.

---

## Coding Conventions

- Language: **C** (C99), compiled with `-Wall -Wdeclaration-after-statement -Wredundant-decls`.
- New Emscripten-specific code belongs in `src/` and must be guarded by
  `#ifdef __EMSCRIPTEN__` where it would conflict with native builds.
- Follow the existing Chocolate Doom style: 4-space indentation, braces on their own
  line for function bodies, K&R-style for control flow.
- Do **not** introduce new third-party C libraries without updating `configure.ac`,
  `Makefile.am`, and this file.
- Shell scripts must start with `#!/bin/bash` and `set -euo pipefail`.

---

## CI / Static Analysis

The only automated workflow is **Semgrep** (`.github/workflows/semgrep.yml`), which
runs on every push to `main`/`master`, on every pull request, and daily.  It uses the
`semgrep/semgrep` Docker image against the Cloudflare Semgrep endpoint.

There is no automated compile/test CI for the Wasm build because it requires
Emscripten to be installed.  When making changes to C source files, manually verify
the build with `./scripts/build.sh`.

---

## What Agents Should and Should Not Do

**Do:**
- Edit C sources under `src/` and `src/doom/`.
- Update `configure.ac` Emscripten flags when required.
- Keep `README.md` in sync with any user-visible changes.
- Update the stdout protocol table in this file and in `README.md` together when
  adding or changing protocol message codes.
- Add or update `tests/` smoke tests for new networking behaviour.

**Do not:**
- Commit binary files, `.wasm`, `.js`, or `.html` build outputs (they are `.gitignore`d).
- Change the numeric stdout protocol codes (they are part of the public API consumed
  by the JS host page and the `doom-workers` relay).
- Enable pthreads (`USE_PTHREADS`) without also setting `PROXY_TO_PTHREAD` and
  coordinating with the WebSockets module — the current build is intentionally
  single-threaded on the Wasm side.
- Remove the `src/doom1.wad` entry from `.gitignore`; WAD files must not be committed.
- Introduce GPL-incompatible dependencies.
