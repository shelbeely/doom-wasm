# Coding Conventions

## C Source

- **Standard:** C99
- **Compiler flags:** `-Wall -Wdeclaration-after-statement -Wredundant-decls`
- **Indentation:** 4 spaces (no tabs) — enforced by `.editorconfig`
- **Brace style:** Opening brace on its own line for function definitions; K&R style
  for control flow (`if`, `for`, `while`)
- **Emscripten-specific code** must be guarded with `#ifdef __EMSCRIPTEN__` anywhere
  it would conflict with a native build

Follow the existing Chocolate Doom style visible throughout `src/`.  New files should
begin with the standard copyright/licence comment block found in other source files.

## Adding a New C Library

Before introducing any new dependency:
1. Add it to `configure.ac` (PKG_CHECK_MODULES or AC_CHECK_LIB)
2. Add it to `src/Makefile.am`
3. Update the prerequisites section of `docs/build.md`
4. Verify it is GPL-compatible (COPYING.md)
5. Note it in `AGENTS.md` under the relevant section

## Shell Scripts

All shell scripts must begin with:

```bash
#!/bin/bash
set -euo pipefail
```

This ensures scripts abort immediately on any error, unset variable, or silent pipe
failure.

## HTML / JavaScript (`src/index.html`)

- Use `const` / `let`; avoid `var`
- Do not add `type="text/javascript"` to `<script>` tags (HTML5 default)
- Keep inline JS minimal — runtime logic belongs in the Wasm module

## Commit Messages

Use the imperative mood and reference the affected module, e.g.:

```
net_websockets: handle reconnect after queue overflow
docs: add packet-framing detail to architecture.md
configure.ac: enable SAFE_HEAP for debug builds
```
