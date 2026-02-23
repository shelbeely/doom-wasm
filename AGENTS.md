# AGENTS.md

This file is the **table of contents** for AI coding agents working in this repository.
Read this first, then follow the links for deeper context on each area.

---

## What This Repo Is

**Wasm Doom** — a [Chocolate Doom](https://github.com/chocolate-doom/chocolate-doom)
WebAssembly port with real-time WebSockets multiplayer, compiled with
[Emscripten](https://emscripten.org/) and served from a browser.
The networking layer replaces SDL_net with a custom WebSockets module.

---

## Repository Layout

```
doom-wasm/
├── AGENTS.md               ← you are here (TOC only — follow links below)
├── ARCHITECTURE.md         ← module map, stdout protocol, packet queue
├── docs/
│   ├── build.md            ← how to build, clean, run, and Emscripten flags
│   ├── conventions.md      ← C style, shell scripts, JS, commit messages
│   ├── SECURITY.md         ← threat model, memory safety, dependency rules
│   └── RELIABILITY.md      ← queue limits, reconnect, memory, error reporting
├── scripts/
│   ├── build.sh            ← full Emscripten build
│   ├── clean.sh            ← remove all generated artefacts
│   └── check.sh            ← mechanical invariant enforcement (run before PR)
├── src/
│   ├── index.html          ← browser entry point
│   ├── net_websockets.c/h  ← sole network backend (Wasm only)
│   ├── debug.h             ← LDEBUG compile-time logging macro
│   ├── doom/               ← Doom-specific game logic
│   └── …                   ← shared Chocolate Doom sources
├── tests/                  ← Emscripten smoke tests
├── configure.ac            ← Autotools + Emscripten flags (EMFLAGS)
└── .editorconfig           ← mechanical style enforcement
```

---

## Where to Look

| Topic | Go to |
|-------|-------|
| Module boundaries, stdout protocol codes | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| How to build / run / clean | [`docs/build.md`](docs/build.md) |
| C style, shell scripts, commit messages | [`docs/conventions.md`](docs/conventions.md) |
| Security threat model and constraints | [`docs/SECURITY.md`](docs/SECURITY.md) |
| Reliability constraints and error handling | [`docs/RELIABILITY.md`](docs/RELIABILITY.md) |
| CI / Semgrep workflow | [`.github/workflows/semgrep.yml`](.github/workflows/semgrep.yml) |
| Emscripten flags | [`configure.ac`](configure.ac) (search `EMFLAGS`) |
| Browser entry point | [`src/index.html`](src/index.html) |

---

## Before Opening a PR

Run the mechanical check script — all checks must pass:

```bash
./scripts/check.sh
```

Checks enforced: shell script safety flags, no tab indentation in C, stdout protocol
code range, no tracked build outputs, required documentation files present.

---

## Hard Rules for Agents

**Do:**
- Edit C sources under `src/` and `src/doom/`.
- Keep `README.md` and `docs/` in sync with any user-visible change.
- When adding/changing a stdout protocol code, update **both** `ARCHITECTURE.md`
  and `README.md` — the codes are a frozen public API.
- Run `./scripts/build.sh` after any C change to verify the build.

**Do not:**
- Commit `.wasm`, `.js`, or `.html` build outputs (gitignored).
- Renumber or reuse stdout protocol codes (`doom: 1` through `doom: 12`).
- Enable `USE_PTHREADS` without also setting `PROXY_TO_PTHREAD` and coordinating with
  `net_websockets.c` — the build is intentionally single-threaded.
- Commit `src/doom1.wad` or any WAD file (gitignored; see `docs/SECURITY.md`).
- Introduce a C library without updating `configure.ac`, `Makefile.am`, and `docs/build.md`.
- Store decisions, context, or rationale in Slack or memory — encode it in `docs/`.

