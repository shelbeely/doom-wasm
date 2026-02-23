# Reliability

## Packet Queue

The WebSocket packet queue (`net_websockets.c`) is a fixed-size circular buffer:

```c
#define MAX_QUEUE_SIZE 64
```

When the queue is full, **incoming packets are silently dropped**.  This is intentional
— the game protocol tolerates packet loss (it mirrors the original UDP-based design).

Do not increase `MAX_QUEUE_SIZE` without profiling heap impact against the 64 MB
`TOTAL_MEMORY` limit.

## Reconnection

When a WebSocket send fails (`doom: 6`), the module sets `inittedWebSockets = false`
and the next tick re-initialises the connection.  The relay server is stateless for
connection purposes; reconnection restores multiplayer state.

## Single-Threaded Constraint

The build runs with `USE_PTHREADS=0`.  All networking, game logic, and rendering
execute on the Wasm main thread via `ASYNCIFY`.  Do not introduce blocking calls
outside of `emscripten_sleep` / ASYNCIFY-wrapped paths.

## Memory

Total heap is fixed at 64 MB (`TOTAL_MEMORY=64MB`, `ALLOW_MEMORY_GROWTH=0`).
Exhausting the heap causes an immediate abort.  Agents must not introduce large static
allocations or unbounded dynamic allocation.

## Browser Compatibility

The build targets any browser with WebAssembly + WebGL + WebSocket support (all
evergreen browsers since ~2018).  Do not add Web APIs with narrower support without
a documented fallback.

## Error Reporting

Runtime errors surface via the stdout protocol (see `ARCHITECTURE.md`).  The browser
host page is expected to monitor `Module.print` for `doom: N` messages and display
appropriate UI.  Do not swallow errors silently — always emit a numbered protocol
message before degrading gracefully.
