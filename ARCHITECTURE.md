# Architecture

## Module Map

```
Browser JS (index.html)
    └── Emscripten runtime (websockets-doom.js / .wasm)
            ├── net_websockets.c   ← sole network backend for Wasm
            ├── d_loop.c           ← game loop + UID/connect logic
            ├── net_server.c       ← server-side session management
            ├── doom/d_net.c       ← game-start coordination
            └── doom/g_game.c      ← game state (fullscreen, etc.)
```

## Networking (`src/net_websockets.c`)

The only network backend for the Wasm build.  It replaces SDL_net entirely.

**Wire format** (binary WebSocket frames):
- Bytes 0–3: little-endian `uint32_t` source IP
- Bytes 4–N: `net_packet_t` payload

Do **not** add SDL_net calls here.  Do **not** call this module from native builds
without an `#ifdef __EMSCRIPTEN__` guard.

## stdout Protocol

Runtime events are sent to the host web page as numbered `printf` lines on stdout.
`Module.print` in `src/index.html` can parse them.

**The numeric codes are a frozen public API** consumed by the JS host page and the
`doom-workers` relay server.  Never renumber them.  Adding a new event requires
assigning the next unused integer and updating the table below **and** `README.md`.

| Code | Message | Source |
|------|---------|--------|
| `doom: 1`  | failed to connect to websockets server | `net_websockets.c` |
| `doom: 2`  | connected to `<url>` | `net_websockets.c` |
| `doom: 3`  | out of client addresses | `net_websockets.c` |
| `doom: 4`  | ws error | `net_websockets.c` |
| `doom: 5`  | ws close | `net_websockets.c` |
| `doom: 6`  | failed to send ws packet, reconnecting | `net_websockets.c` |
| `doom: 7`  | failed to connect to `<addr>` | `d_loop.c` |
| `doom: 8`  | uid is `<n>` | `d_loop.c` |
| `doom: 9`  | disconnected from server | `d_loop.c` |
| `doom: 10` | game started | `doom/d_net.c` |
| `doom: 11` | entering fullscreen | `doom/g_game.c` |
| `doom: 12` | client `<name>` timed out and disconnected | `net_server.c` |

## Packet Queue (`net_websockets.c`)

Fixed-size circular buffer: `MAX_QUEUE_SIZE = 64` entries.  If full, incoming packets
are **silently dropped**.  Do not change this behaviour without also updating the
queue-full handling path and documenting the change here.

## Debug Logging (`src/debug.h`)

```c
#define LDEBUG 0   // set to 1 to enable

#ifdef LDEBUG
#define D(x) x
#else
#define D(x)
#endif
```

All `D(x)` calls compile to nothing when `LDEBUG` is `0` (the default).  Do not add
unconditional `printf` calls to hot paths; use `D(...)` instead.

## Browser Entry Point (`src/index.html`)

Loads `websockets-doom.js`, preloads `doom1.wad` and `default.cfg` into the Emscripten
virtual FS, then calls `callMain(commonArgs)`.

**Critical constraint:** The `<canvas>` element must have zero CSS border and zero
padding.  Any border or padding shifts mouse coordinates and breaks input.
