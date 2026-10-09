# 🐀 ratmode

> **Context-frugal navigation for coding agents.**  
> *Frugal, not reckless*: a saving that reduces accuracy is not a saving, because a cheap but wrong answer costs more to fix.

[🇪🇸 Leer en español](README.es.md)

`ratmode` gives coding agents a disciplined way to navigate repositories without wasting context:

> **`Hypothesize → Locate → Read → Verify → Stop`**

> **Status:** `v0.1, unbenchmarked`. These rules stem from technical reasoning and day-to-day practice, not yet from formal benchmark suites. See [Status & Evaluation](#-status--evaluation).

---

## ⚡ The Problem

When assigned a task, an autonomous agent defaults to over-exploration: it opens files *"just in case"*, browses directory trees out of curiosity, and ingests thousands of irrelevant lines before forming a hypothesis.

This wastes tokens and dilutes critical system instructions with noise, degrading reasoning quality and inducing regressions.

```text
Without ratmode:
Task → ls → read files "just in case" → search → read more files → 💸 context wasted

With ratmode:
Task → Hypothesis → Locate → Targeted read → Checkpoint → Fix → 🛑 Stop
```

---

## 🏛️ The ratmode System

`ratmode` is not just a prompt; it is a lightweight 3-pillar navigation discipline:

```text
                    ratmode
                       │
        ┌──────────────┼──────────────┐
        ↓              ↓              ↓
  Token Firewall    RatIndex      Checkpoints
   limits waste   targeted map  halts wandering
```

* **Token Firewall:** Requires a provisional 1-line hypothesis before reading; bans exploratory browsing and checks confirmation bias.
* **RatIndex:** An optional, structurally verified navigation map for large codebases.
* **Checkpoints:** A circuit breaker after inspecting ~10 files or ~2,000 lines without new evidence.

> **Meta-rule:** `ratmode` rules are optimization heuristics, not dogmatic quotas. Do not minimize reading for the sake of it: minimize reading that does not increase the probability of correctly solving the task. If any rule costs more context than it saves on the current task, do not apply it.

---

## 📜 The Rules

| Rule | In One Line |
| :--- | :--- |
| **Check repo rules first** | Inspect `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md` before exploring. Project-specific governance always dictates behavior. |
| **Code is source of truth** | If an index or documentation disagrees with source code, update the reference. Code always wins. |
| **Hypothesis first (Falsifiable)** | State in one line what you seek and where you expect it. Treat it as provisional: discard or update it immediately if evidence contradicts it. Skip if files were pre-specified. |
| **Locate before reading** | Search by symbol, endpoint, or ID (`rg -n`, `grep -n`) before opening files. Global search is allowed with sensible limits (`-w`, `-l`, `head`, exclude dependencies). |
| **Smallest semantic unit** | Read the smallest complete semantic unit sufficient to validate the hypothesis (method, function, hook with relevant types/imports; whole file if <300 lines). No blind fixed-line windows. |
| **Check callers & references** | Before changing public or exported signatures, inspect direct callers across the codebase using LSP/AST references (or targeted `grep -nw`). |
| **Measure without reading** | Use `ls`, `find`, `wc -l`, or `git ls-files` to inspect volume and structure instead of opening file contents solely for measurement. |
| **Exploration checkpoint** | After inspecting ~10 files or ~2,000 lines without producing **new evidence**: stop, summarize ruled-out hypotheses, state the current lead, and plan the next step. Do not confuse *no solution yet* with *no new evidence*. |
| **Zero code invasion** | Never insert artificial navigation tags (`// [NAV]`) into source code. Anchors must be pre-existing native identifiers. |

---

## 🚀 Quick Start

### Option A: Drop the rule block into your project rules
Works in any agentic tool. Add this block to `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`. Note that tool config paths can change (Cursor: `.cursor/rules` (or `.cursorrules`); Aider: `CONVENTIONS.md`. Check each tool's docs for the exact path):

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

### Option B: Install as an Agent Skill
If your tool supports the Agent Skills standard, copy this folder into your skills directory (e.g., in Claude Code: `.claude/skills/ratmode/` for project-level or `~/.claude/skills/ratmode/` globally). The agent will automatically trigger it when prompted with "rat mode", "ratmode", "save context", "reduce tokens", "create an index", "INDEX.md", or adding navigation rules to `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`.

---

## 🗺️ RatIndex: Structurally Verified Map (Optional)

`RatIndex` is the optional repo-mapping module of `ratmode`: a single `INDEX.md` routing table that points the agent toward key modules. Verification is a **textual existence check**: every listed identifier or path appears somewhere in the codebase. It does not confirm that a symbol is defined (a match in a comment or string counts) nor that its description is still accurate.

It is only worth creating in larger repositories with wide search spaces; in small codebases, maintaining a map costs more context than it saves.

| Size (Source files, excluding vendor/dist) | Strategy |
| :--- | :--- |
| **< 50 files** | No index. Use `ls` and symbol lookups. |
| **50 to 300 files** | Optional: a single `INDEX.md` at root, max 40 lines. |
| **> 300 files, monorepos, or decoupled domains** | Root `INDEX.md` as top-level router, with on-demand `indices/NN_module.md` cards only for complex domains. |

*Do not create an index if your tool already generates an AST repo-map (like Aider) or if you prefer not to.*

### Format

```markdown
### Module (`path/dir/`)
- `identifier`: core responsibility in 3 to 5 words.
- ⚠️ Gotcha, hidden dependency, or critical technical rule in 1 line.
```

A short 3-module illustration is available in [`examples/INDEX.md`](examples/INDEX.md). Enclose **only exact identifiers and paths** in backticks: verification scripts extract these tokens directly and will flag any plain text or shell commands as missing symbols.

### Verification

An unmaintained index rots rapidly. Run verification to confirm that every listed token exists in the codebase:

```bash
# Linux, macOS, WSL, Git Bash
./scripts/verify_index.sh INDEX.md
# Or pointing to an explicit repository root:
./scripts/verify_index.sh INDEX.md path/to/repo

# Windows (PowerShell)
.\scripts\verify_index.ps1 -IndexFile "INDEX.md"
# Or pointing to an explicit repository root:
.\scripts\verify_index.ps1 -IndexFile "INDEX.md" -RootPath "path\to\repo"
```

The scripts exit with code `0` if all symbols match, or `1` if any symbol was renamed or deleted. To keep the map alive: whoever modifies or renames a listed symbol updates its line in the same commit.

---

## 🛑 When NOT to Use It

- **Small repositories:** Directory listings and symbol search suffice; an index is pure overhead.
- **Trivial tasks or pre-specified files:** No ceremony needed; the rules explicitly allow direct edits.
- **Tools with native AST maps:** If your tool generates a dynamic map (e.g. Aider), an `INDEX.md` file is redundant.

---

## 🔬 Status & Evaluation

`ratmode` is at `v0.1` and currently unbenchmarked. The core question is whether it reduces token consumption without hurting task success rates. If you experiment with it, please share your findings in an issue:
1. A real-world task run with and without `ratmode`.
2. Total input/output tokens and tool calls for each run.
3. Whether the task was resolved correctly.

*A benchmark showing lower accuracy is just as valuable as one showing savings.*

---

## 📁 Repository Structure

```text
ratmode/
├── README.md           # English documentation (this file)
├── README.es.md        # Spanish documentation (informational)
├── SKILL.md            # Complete agent skill specification
├── LICENSE             # MIT License
├── scripts/
│   ├── verify_index.sh # Bash verification script
│   └── verify_index.ps1# Optimized PowerShell verification script
└── examples/
    └── INDEX.md        # RatIndex example (3-module illustration)
```

---

## 📄 License

MIT. See [LICENSE](LICENSE).  
Author: [ako-bot](https://github.com/ako-bot).
