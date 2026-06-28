# NEXT_SESSION.md

**Date:** 2026-06-28  
**Previous session commit:** `86fff6c` — "Add 5 gameplay iterations: springs, checkpoints, piranhas, star power-up, fire flower"

---

## What Was Done This Session

Implemented 5 new gameplay features for tl-platformer:

1. **Spring blocks** — Bounce player up with high velocity, spawned every 15th ground tile
2. **Checkpoints** — Respawn at last reached 25% milestone instead of level start
3. **Piranha plants** — Enemies that emerge from pipe-top tiles on a timer
4. **Star power-up** — 10s invincibility, kills enemies on contact, yellow flash overlay
5. **Fire flower + fireballs** — S-key shooting, kills enemies, fire flower from question blocks when big

All features compile successfully (linker errors for Raylib are expected in this environment).

---

## Critical Issue: LSP Mutation Tools Are Broken

**Every `typelisp_edit_*` mutation operation times out after 60s.** This is the #1 blocker for efficient development.

### Tools That Work (Read-Only)
| Tool | Status |
|------|--------|
| `typelisp_edit_check` | Fast (~3-5s), reliable |
| `typelisp_edit_list` | Fast, reliable |
| `typelisp_edit_read` | Fast, reliable |
| `typelisp_edit_expand_macro` | Fast, reliable |

### Tools That Fail (Mutation)
| Tool | Status | Error |
|------|--------|-------|
| `typelisp_edit_insert_after` | Broken | 60s timeout |
| `typelisp_edit_append` | Broken | 60s timeout |
| `typelisp_edit_patch` | Broken | 60s timeout |
| `typelisp_edit_replace` | Broken | 60s timeout |

---

## Root Cause Hypotheses (To Investigate)

### Hypothesis A: LSP Incremental Sync is Broken
Read ops work (no mutation), write ops hang (mutation involved). The server may:
- Enter infinite loop recomputing diagnostics
- Deadlock on document lock
- Fail to apply edit and wait forever

**Test:** Start `typelisp lsp` with verbose logging, send initialize + didOpen + edit via netcat, see where it hangs.

### Hypothesis B: Full Recompile on Every Edit
The typelisp compiler may not have incremental compilation. 18 .tl files could take >60s to re-typecheck.

**Test:** `time ~/workspace/typelisp/target/stage2/typelisp check src/main.tl`
If this takes >30s, confirmed.

### Hypothesis C: LSP Doesn't Support `workspace/applyEdit`
The server may receive edit requests but not know how to handle them, never responding.

**Test:** Check LSP `initialize` response for `workspace.workspaceEdit` capabilities.

### Hypothesis D: JSON-RPC Deadlock
Single-threaded LSP may block on diagnostics computation and not read stdin for the response.

**Test:** Check if LSP spawns background threads for diagnostics in typelisp source.

---

## Diagnostic Commands to Run (Priority Order)

```bash
# 1. Check if full typecheck is the bottleneck
cd ~/workspace/tl-platformer && time ~/workspace/typelisp/target/stage2/typelisp check src/main.tl

# 2. Check if build (typecheck + link) is the bottleneck
cd ~/workspace/tl-platformer && time ~/workspace/typelisp/target/stage2/typelisp build src/main.tl

# 3. Test mutation on a minimal file (rules out project size)
cat > /tmp/lsp_test.tl << 'EOF'
(define x : i64 1)
EOF
# (then try typelisp_edit_append on this file)

# 4. Check LSP process health during an edit
ps aux | grep -i typelisp
# Watch CPU/memory while mutation tool is running

# 5. Check LSP capabilities
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | \
  ~/workspace/typelisp/target/stage2/typelisp lsp 2>&1 | head -100

# 6. Find LSP implementation in typelisp source
grep -r "workspace.*applyEdit\|textDocument.*didChange\|lsp" \
  ~/workspace/typelisp/src/ --include="*.rs" 2>/dev/null
```

---

## Potential Fixes (Research Needed)

| Fix | Description | Feasibility |
|-----|-------------|-------------|
| **A** | Increase tool timeout | Low — 60s is already generous |
| **B** | Fix LSP incremental sync | Medium — requires Rust/compiler knowledge |
| **C** | Formalize "edit then check" workflow | High — no LSP changes needed |
| **D** | Batch mutations into single call | Medium — requires new tool |
| **E** | Add pre-validation tool | High — client-side or simple LSP extension |

**Recommended:** Start with Fix C (document the workaround) and Fix E (pre-validation). Fix B is the real solution but requires compiler work.

---

## Language-Level Issues (Filed as Issues)

| Issue | Example | Workaround Used |
|-------|---------|-----------------|
| No n-ary `+`/`*` | `(+ a b c)` fails | `(+ (+ a b) c)` |
| `let` in `while` body | `(while x (begin (let ...) (set! ...)))` fails | Restructure nesting |
| `when` body must return unit | `(when x (bool-expr))` fails | Wrap in `(begin ... unit)` |
| No `abs` for f64 | `(abs x)` unbound | Define custom `abs-f64` |
| Wrong error locations | Error at `main.tl:54` was in `piranha.tl:54` | Manually trace imports |
| Parameter `set!` banned | Can't mutate function args | Use globals |

---

## Immediate Workaround (Until LSP Fixed)

1. Draft edits in `/tmp/test_*.tl` files first
2. Validate with `typelisp_edit_check`
3. Apply to production files via `edit` tool (raw text replacement)
4. Validate production file with `typelisp_edit_check`
5. Use Python paren checker for complex nested edits

---

## What's Next

1. **Run diagnostics** from the commands above to identify root cause
2. **File issue** in typelisp repo with findings
3. **Consider** whether to implement Fix E (pre-validation tool) as a standalone script
4. **Continue** gameplay iterations once tooling is usable
