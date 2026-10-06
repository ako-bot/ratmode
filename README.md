# 🐀 ratmode

> **Context-frugal navigation for coding agents.**  
> *Frugal, not reckless*: a saving that reduces accuracy is not a saving, because a cheap but wrong answer costs more to fix.

[🇪🇸 Leer en español](README.es.md)

`ratmode` gives coding agents a disciplined way to navigate repositories without wasting context:

> **`Locate → Hypothesize → Read → Verify → Stop`**

> **Status:** `v0.1, unbenchmarked`. These rules stem from technical reasoning and day-to-day practice, not yet from formal benchmark suites. See [Status & Evaluation](#-status--evaluation).

---

## ⚡ The Problem

When assigned a task, an autonomous agent defaults to over-exploration: it opens files *"just in case"*, browses directory trees out of curiosity, and ingests thousands of irrelevant lines before forming a hypothesis.

This wastes tokens and dilutes critical system instructions with noise, degrading reasoning quality and inducing regressions.

```text
Without ratmode:
Task → ls → read files "just in case" → search → read more files → 💸 context wasted

With ratmode:
Task → Locate → Hypothesis → Targeted read → Checkpoint → Fix → 🛑 Stop
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

* **Token Firewall:** Requires a 1-line hypothesis before reading; bans exploratory browsing.
* **RatIndex:** An optional, verifiable, zero-rot map for large codebases.
* **Checkpoints:** A hard circuit breaker after inspecting ~10 files or ~2,000 lines without a solution.

---

## 📜 The Rules

| Rule | In One Line |
| :--- | :--- |
| **Locate before reading** | Search by symbol, endpoint, or ID (`rg -n`, `grep -n`) before opening files. Global search is allowed with sensible limits (`-w`, `-l`, `head`, exclude dependencies). |
| **Hypothesis first** | State in one line what you are looking for and where you expect it to be. If the user already named the file, go straight to it. |
| **Read complete units** | Read the full symbol with its imports and surrounding types, or the entire file if under ~300 lines. Avoid arbitrary fixed-line windows that sever context. |
| **Exploration checkpoint** | After inspecting ~10 files or ~2,000 lines without isolating the root cause: stop, summarize ruled-out hypotheses, state the current lead, and plan the next step. |
| **Zero code invasion** | Never insert artificial navigation tags (`// [NAV]`) into source code. Anchors must be pre-existing native identifiers. |
| **Code is source of truth** | If an index or documentation disagrees with source code, update the reference. Code always wins. |

*Thresholds are advisory warning signals, not pedantic quotas. The golden rule: if any rule costs more context than it saves on the current task, do not apply it.*

---

## 🚀 Quick Start

### Option A: Drop the rule block into your project rules
Works in any agentic tool. Add this block to `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`. For Cursor, add it to `.cursor/rules` (or `.cursorrules`); for Aider, add it to `CONVENTIONS.md`:

```markdown
## Frugal navigation (ratmode)
- Locate by symbol, endpoint, or ID (`rg -n` or `grep -n`) before opening files; never explore out of curiosity.
- When exploring, state in one line what you seek. Skip this if files were already specified.
- Read complete symbols with imports and types (or entire file if <300 lines), not arbitrary line windows.
- Global search is permitted with limits: `-w`, `-l`, `head`, excluding `node_modules`, `dist`, and `.git`.
- After ~10 files or ~2,000 lines without isolating the cause, stop and summarize: ruled out, current lead, next step.
- Output direct diagnostics and minimal unified diffs; no conversational filler.
- If INDICE.md exists, keep listed symbols updated. If code and index disagree, code wins.
```

### Option B: Install as an Agent Skill
If your tool supports the Agent Skills standard, copy this folder into your skills directory (e.g., in Claude Code: `.claude/skills/ratmode/` for project-level or `~/.claude/skills/ratmode/` globally). The agent will automatically trigger it when prompted with *"ratmode"*, *"save context"*, or *"create an index"*.

---

## 🗺️ RatIndex: Verifiable Map (Optional)

`RatIndex` is the optional repo-mapping module of `ratmode`: a single `INDICE.md` routing table that points the agent toward key modules. It is only worth creating in larger repositories; in small codebases, maintaining a map costs more context than it saves.

| Size (Source files, excluding vendor/dist) | Strategy |
| :--- | :--- |
| **< 50 files** | No index. Use `ls` and symbol lookups. |
| **50 to 300 files** | Optional: a single `INDICE.md` at root, max 40 lines. |
| **> 300 files, monorepos, or decoupled domains** | Root `INDICE.md` as top-level router, with on-demand `indices/NN_module.md` cards only for complex domains. |

*Do not create an index if your tool already generates an AST repo-map (like Aider) or if you prefer not to.*

### Format

```markdown
### Module (`path/dir/`)
- `identifier`: core responsibility in 3 to 5 words.
- ⚠️ Gotcha, hidden dependency, or critical technical rule in 1 line.
```

An example is available in [`examples/INDEX.md`](examples/INDEX.md). Enclose **only exact identifiers and paths** in backticks: verification scripts extract these tokens directly and will flag any plain text or shell commands as missing symbols.

### Verification

An unmaintained index rots rapidly. Run verification to confirm that every listed token exists in the codebase:

```bash
# Linux, macOS, WSL, Git Bash
./scripts/verify_index.sh INDICE.md

# Windows (PowerShell)
.\scripts\verify_index.ps1 -IndexFile "INDICE.md"
```

The scripts exit with code `0` if all symbols match, or `1` if any symbol was renamed or deleted. To keep the map alive: whoever modifies or renames a listed symbol updates its line in the same commit.

---

## 🛑 When NOT to Use It

- **Small repositories:** Directory listings and symbol search suffice; an index is pure overhead.
- **Trivial tasks or pre-specified files:** No ceremony needed; the rules explicitly allow direct edits.
- **Tools with native AST maps:** If your tool generates a dynamic map (e.g. Aider), an `INDICE.md` file is redundant.

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
├── README.es.md        # Spanish documentation
├── SKILL.md            # Complete agent skill specification
├── LICENSE             # MIT License
├── scripts/
│   ├── verify_index.sh # Bash verification script
│   └── verify_index.ps1# Optimized PowerShell verification script
└── examples/
    ├── INDEX.md        # RatIndex English example
    └── INDICE.md       # RatIndex Spanish example
```

---

## 📄 License

MIT. See [LICENSE](LICENSE).  
Author: [ako-bot](https://github.com/ako-bot).
