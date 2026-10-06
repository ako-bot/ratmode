---
name: ratmode
description: Context-budget discipline for AI coding agents (Claude Code, Cursor, Aider, Antigravity). Navigate by symbols instead of reading whole files, with exploration checkpoints and, for large repos only, a verifiable INDEX.md (RatIndex). Use when the user requests "rat mode", "ratmode", "save context", "reduce tokens", "create an index", "INDEX.md", or adding navigation rules to CLAUDE.md, AGENTS.md, or GEMINI.md.
---

# ratmode v0.1: surgical navigation

> **Guiding Principle:** Spend context only where it moves you closer to the solution. Do not minimize reading for the sake of it: minimize reading that does not increase the probability of correctly solving the task.
> 
> **Meta-rule:** `ratmode` rules are optimization heuristics, not dogmatic quotas. If any rule in this document costs more context than it saves on the current task, do not apply it.

## 1. Navigation Rules

1. **Check repository rules first** (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) if present. Repository-specific conventions always govern agent behavior.
2. **Code is source of truth.** Indexes and documentation are a GPS. If they disagree with source code, update the reference. Code always wins.
3. **Hypothesis before exploration (Falsifiable & Anti-Anchoring).** Before opening files to locate something, state in one line what you seek and where you expect it to be ("Looking for JWT expiration logic, likely in `auth/`"). Treat this hypothesis as strictly provisional: update or discard it immediately when code or search evidence contradicts it to avoid confirmation bias. Skip this step for files the user already specified or obvious single-file edits.
4. **Locate before reading.** Search with `rg -n` or `grep -n` by symbol, endpoint route, or semantic ID, scoping to the relevant module when known. If unknown, global search is permitted with constraints: whole word (`-w`), filenames only (`-l`), or `| head -20`, excluding `node_modules`, `.git`, `dist`, `build`, `venv`, and caches. For generic names (`save`, `init`, `render`), combine two terms or scope by directory.
5. **Read smallest complete semantic units.** Read the smallest complete semantic unit sufficient to validate the current hypothesis (a specific function, method, or hook rather than an entire 800-line God component), including relevant imports, types, or nearby constants as needed. If the file is under ~300 lines, read the entire file. Avoid arbitrary fixed-line ranges: they sever context right where it matters most.
6. **Check callers and references before changing signatures.** Before modifying any public or exported signature, search for direct callers and references across the codebase; use the Language Server (LSP) or AST references when available, falling back to targeted `grep -nw`.
7. **Measure without reading.** Use `ls`, `find`, `wc -l`, or `git ls-files` to inspect volume and structure instead of opening file contents solely for measurement. Ignore vendor dependencies, build artifacts, binaries, and generated files.
8. **Zero code invasion.** Never insert artificial comments or navigation markers into source code. Anchors must be existing native identifiers: exported symbols first (classes, functions, components, interfaces), then API endpoints and selectors/IDs.

## 2. Exploration Checkpoint

Warning threshold: ~10 distinct files or ~2,000 lines inspected without isolating the root cause. Double this threshold in large repos or cross-cutting architectural bugs. No exact line counting needed; it serves as a wake-up signal that you may be wandering.

When reached:
1. Stop opening new files.
2. Output a 3-line checkpoint: what hypotheses you ruled out, what the strongest lead is now, and what you propose to inspect next.
3. If an interactive user is present, ask for guidance. In autonomous mode, proceed with your strongest lead and leave the checkpoint summary in your output. If two consecutive checkpoints produce **no new evidence**, halt and ask (distinguish between *"no root cause isolated yet"* and *"no new evidence produced"*).

## 3. Do You Need a Repo Map? (RatIndex: Structurally Verified Map)

RatIndex provides a **structurally verified navigation map**. Verification guarantees referential integrity (symbols physically exist in the codebase), though not semantic freshness.

Decide by count of source files (excluding dependencies and generated code): what makes navigation expensive is the number of candidate locations to search, not total lines.

| Size (Advisory) | Strategy |
|---|---|
| < 50 files | No index. Use `ls` and symbol lookups. A map costs more than it saves. |
| 50 to 300 files | Optional: a single root `INDEX.md`, max 40 lines. |
| > 300 files, monorepos, or decoupled domains | Root `INDEX.md` as top-level router, with on-demand `indices/NN_module.md` cards only for complex domains. |

Do not create an index if the tool already provides an AST-based repo-map (e.g. Aider) or if the user prefers not to. Thresholds are advisory: a small codebase with unusually large or cryptic files may still benefit from a map.

## 4. Creating or Updating a Map (RatIndex)

**Prior proposal.** Before writing, present a brief plan (max 4 lines): diagnostics (file count, approximate lines, strategy) and which files will be created or modified (confirming source code remains 100% untouched). Wait for user confirmation ("proceed"). This pause applies only to navigation documentation, never to routine coding tasks.

**Format**, no filler:

```markdown
### Module (`path/dir/`)
- `identifier`: core responsibility in 3 to 5 words.
- ⚠️ Gotcha, hidden dependency, or critical technical rule in 1 line.
```

Enclose **only exact identifiers and paths** in backticks, exactly as they exist in source code: verification scripts parse these tokens directly.

**Verification.** Run `./scripts/verify_index.sh INDEX.md` (Linux/macOS) or `.\scripts\verify_index.ps1 -IndexFile "INDEX.md"` (Windows PowerShell) and resolve every discrepancy (renamed or deleted symbols) before completing the map.

**Maintenance.** An unowned index rots. If you add, rename, or delete a listed symbol, update its line in the same commit. If the verification script fails at the start of a session, fix the index before trusting it.

## 5. Drop-in Block for CLAUDE.md, AGENTS.md, or GEMINI.md

If an instruction file exists, propose adding this block:

```markdown
## Frugal navigation (ratmode)
- Treat these as heuristics, not quotas: if a rule costs more context than it saves on the current task, skip it.
- Check repository rules first; never explore out of curiosity.
- Locate by symbol, endpoint, or ID (`rg -n` or `grep -n`) before opening files.
- When exploring, state in one line what you seek; discard the hypothesis as provisional if search contradicts it.
- Read smallest complete semantic units (functions/methods with imports and types; whole file if <300 lines), not arbitrary line windows.
- Check callers/references (LSP/AST or `grep -nw`) before changing public signatures.
- Global search is permitted with limits: `-w`, `-l`, `head`, excluding `node_modules`, `dist`, and `.git`.
- Checkpoint: After ~10 files or ~2,000 lines without new evidence, stop and summarize: ruled out, current lead, next step.
- Output direct diagnostics and minimal unified diffs; no conversational filler.
- If INDEX.md exists, keep listed symbols updated. If code and index disagree, code wins.
```

## 6. Output Discipline

Respond in the user's language with direct technical diagnostics and minimal unified diffs. If you created or modified navigation files, close with a single summary line: modified files, source code untouched, and verification result (N symbols, M discrepancies). If no files were modified, omit closure commentary.
