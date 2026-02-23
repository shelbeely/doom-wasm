# Security

## Network Attack Surface

The only network entry point in the Wasm build is `src/net_websockets.c`.  It opens
one outbound WebSocket connection to the relay server URL passed via `-servername`.
There is no inbound listener; the browser sandbox enforces the origin policy.

**Threat model:** the relay server (`doom-workers`) is trusted.  Packets from the
relay are treated as authoritative; there is no per-packet authentication.  A
compromised or spoofed relay can send arbitrary game packets.

## Packet Handling

Incoming binary frames are structured as:
- Bytes 0–3: little-endian `uint32_t` source IP (relay-assigned, not verified by client)
- Bytes 4–N: `net_packet_t` payload — parsed by the existing Chocolate Doom net layer

Agents must **not** use the source IP field for trust decisions.  It is metadata only.

## Memory Safety

The Wasm build compiles with `-s SAFE_HEAP=1` and `-s STACK_OVERFLOW_CHECK=1`.
These are compile-time guards; keep them enabled.

Do not disable these flags to work around a bug — fix the root cause instead.

## Emscripten Sandbox

The game runs entirely inside the browser's WebAssembly sandbox.  File system access
is via Emscripten's virtual FS (MEMFS); no real host filesystem is accessible.

## WAD Files

`doom1.wad` and all other WAD files are gitignored and must **never** be committed.
The shareware WAD is freely distributable but the full game WAD is commercial.

## Dependencies

All C dependencies come from Emscripten's bundled SDL2 ports or from the Chocolate
Doom source tree.  Do not introduce network-fetched dependencies at build time.
New libraries must be GPL-compatible; see `COPYING.md`.
