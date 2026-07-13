---
description: Bootstrap & validate the agent factory in this project — generate .claude/factory/config.md from the template, verify prerequisites, and check agent registration.
argument-hint: "(no arguments)"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Bash(git *), Bash(gh *), Bash(ls *), Bash(cat *), Bash(node *), Bash(npm *), Bash(npx *)
---

You are bootstrapping the **agent factory** in this project. Work through the
checks in order, fix what you can automatically, and finish with a clear
PASS/FIX report. Do not modify application code.

## 1. Verify prerequisites

- **Git repo:** `git rev-parse --is-inside-work-tree`. If not, stop and offer
  `git init`.
- **PR tool:** `gh auth status`. If missing/unauthenticated, report it (the
  factory can run through IMPLEMENTING without it, but not open PRs).
- **Factory files present:** `.claude/factory/protocol.md`,
  `.claude/factory/conventions.md`, `.claude/factory/config.template.md` (or
  an existing `config.md`), `.claude/factory/scripts/context-usage.mjs`
  (verify it runs: `node .claude/factory/scripts/context-usage.mjs` — an
  error is OK outside a live session, but "node: not found" means context
  checkpoints will fall back to estimates), `.claude/commands/feature.md`,
  the seven agents
  in `.claude/agents/` (`product-owner`, `ux-designer`, `tech-lead`,
  `senior-dev`, `code-reviewer`, `qa-lead`, `qa-runner`), and the three
  skills in `.claude/skills/` (`commit`, `create-pr`, `factory-docs`). List
  anything missing — the install script (`install.ps1` / `install.sh` from
  the factory repo) copies these.
- **Standards doc:** look for `CLAUDE.md` at the repo root. If none exists,
  ask whether to create a minimal one now (the factory needs *some*
  conventions source; suggest running Claude Code's `/init` first) or point
  the config at another doc.

## 2. Generate `.claude/factory/config.md`

If `config.md` already exists, **do not overwrite it** — diff it against the
template's section list and only report missing sections (e.g. an old config
without the Gate policy table).

Otherwise, copy `config.template.md` → `config.md` and fill the placeholders
by detection, asking only for what you cannot detect:

- **Commands:** read `package.json` scripts (or the equivalent for the stack —
  `Makefile`, `pyproject.toml`, `Cargo.toml`): typecheck, lint, test,
  test-single-file, build, dev (+ dev URL from the framework's default), seed.
  Verify each detected command parses (`--help` / `--version` level; do not
  run builds or tests).
- **Paths:** default `docs/tickets`, `src`, `.claude/worktrees`. Ensure
  `.claude/worktrees` is in `.gitignore` (append it if not — this is a config
  file, not app code). Create `docs/tickets/README.md` if absent (one
  paragraph pointing at protocol.md + config.md).
- **Workflow:** default branch from `git remote show origin` (fallback: the
  current branch); branch naming `feat/{id}` / `fix/{id}`; platform notes —
  on Windows, insert the Git-Bash + `npx kill-port` note automatically.
- **Role → standards sections:** read the standards doc's top-level headings
  and propose a mapping per role (product-owner: overview/product sections;
  ux-designer: component/UI sections; tech-lead: structure + feature + testing
  rules; senior-dev: implementation-facing sections; qa-lead: testing +
  routes; qa-runner: routes + test accounts). Show the proposal; let the user
  adjust via one AskUserQuestion if the headings are ambiguous.
- **Models / Gate policy / Lanes:** keep the template defaults unless the user
  says otherwise.
- **Design skill:** `Glob` `.claude/skills/*/SKILL.md`; if a design-oriented
  skill exists, propose it, else delete the section.
- **Notifications:** ask (hook / push / none) — one question, default none.

## 3. Validate agent registration

Claude Code loads `.claude/agents/*.md` at **session start**. If any factory
agent file was just installed in this session, tell the user plainly:
**"Reload the session before running `/feature` — newly added agents are not
yet registered as subagent types."** (Do not attempt to launch agents to test
this; just check file presence + frontmatter validity: `name`, `description`,
`tools`, `model` fields parse.)

## 4. Report

Finish with a checklist:

```
## Factory init — {project}
- [x] git repo · gh authenticated
- [x] factory files installed (7 agents, feature.md, protocol.md)
- [x] config.md generated (typecheck/lint/test/build detected)
- [x] docs/tickets/ ready · .claude/worktrees gitignored
- [ ] SESSION RELOAD REQUIRED before first /feature   ← if applicable
Next: run `/feature <your first request>` (or `/feature lane:hotfix <tiny fix>`).
```

Anything you could not detect or verify goes in the report as an explicit
open item — never silently assume.
