#!/bin/bash
# scripts/check.sh — mechanical enforcement of repository invariants.
# Run this before opening a PR.  All checks must pass (exit 0).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ERRORS=0

fail() {
    echo "FAIL: $*" >&2
    ERRORS=$((ERRORS + 1))
}

# ── 1. Shell scripts must have set -euo pipefail ────────────────────────────
while IFS= read -r -d '' script; do
    if ! grep -q "set -euo pipefail" "$script"; then
        fail "$script is missing 'set -euo pipefail'"
    fi
done < <(find "$ROOT/scripts" -name "*.sh" -print0)

# ── 2. Wasm-port C files must not use hard-tab indentation ──────────────────
# Only checks files that carry the Cloudflare/Wasm-port copyright; upstream
# Chocolate Doom files use the original Doom tab style and are not changed.
while IFS= read -r -d '' cfile; do
    if head -5 "$cfile" | grep -qi "cloudflare\|wasm"; then
        if grep -Pq "^\t" "$cfile"; then
            fail "$cfile contains tab indentation (use 4 spaces)"
        fi
    fi
done < <(find "$ROOT/src" -name "*.[ch]" -print0)

# ── 3. stdout protocol codes must not exceed the documented maximum ──────────
# Codes doom: 1–12 are frozen.  A new code requires updating ARCHITECTURE.md.
MAX_KNOWN=12
while IFS= read -r -d '' cfile; do
    while IFS= read -r line; do
        if [[ "$line" =~ doom:\ ([0-9]+) ]]; then
            code="${BASH_REMATCH[1]}"
            if (( code > MAX_KNOWN )); then
                fail "$cfile emits 'doom: $code' but ARCHITECTURE.md only documents up to doom: $MAX_KNOWN — update the table"
            fi
        fi
    done < "$cfile"
done < <(find "$ROOT/src" -name "*.[ch]" -print0)

# ── 4. Build outputs must not be tracked ─────────────────────────────────────
# src/index.html is a committed source file; all other .html/.js/.wasm are outputs.
while IFS= read -r tracked; do
    case "$tracked" in
        src/index.html) ;;  # source file — allowed
        *.html|*.js|*.wasm)
            fail "tracked build output: $tracked — should be gitignored" ;;
        *doom1.wad|*doom2.wad|*.wad)
            fail "tracked WAD file: $tracked — WAD files must not be committed" ;;
    esac
done < <(git -C "$ROOT" ls-files)

# ── 5. Required documentation files must exist ───────────────────────────────
for required in AGENTS.md ARCHITECTURE.md docs/build.md docs/conventions.md \
                docs/SECURITY.md docs/RELIABILITY.md; do
    if [[ ! -f "$ROOT/$required" ]]; then
        fail "required documentation file missing: $required"
    fi
done

# ── Report ────────────────────────────────────────────────────────────────────
if (( ERRORS > 0 )); then
    echo ""
    echo "$ERRORS check(s) failed." >&2
    exit 1
fi

echo "All checks passed."

