---
description: Bootstrap & validate the agent factory in this project — generate .claude/factory/config.md from the template (or sync an existing config with the installed factory version), verify prerequisites, and check agent registration.
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

## 2. Generate or sync `.claude/factory/config.md`

Two modes, decided by whether `config.md` exists:

### 2a. SYNC mode — `config.md` exists (never overwrite it)

Reconcile the existing config with the installed factory version, additively:

1. **Diagnose versions.** Read `.claude/factory/VERSION` (installed factory)
   and the config's `factory version:` stamp. Open the sync with both, e.g.
   *"Installed factory: v2.1.0 · config last synced: v2.0.1."* Missing
   `VERSION` file → a pre-v2.1.0 install; suggest re-running the installer.
   Missing stamp → fine; the section diff below is the source of truth.
2. **Diff sections.** Compare the `## `-level sections of
   `config.template.md` against `config.md`. For each template section the
   config lacks: one line on what it does + the proposed content (values
   detected per the rules in 2b where possible, template defaults otherwise),
   then ask **add / skip** (one AskUserQuestion; chunk if more than 4).
   Never modify a section that exists — its values are the project's.
   Sections in the config that are *not* in the template are project-custom:
   list them as "left alone", never delete or edit them.
3. **Reconcile the design skill.**
   - Config **names a skill**: verify that exact name is registered in this
     session (check the session's available-skills list, not just
     `.claude/skills/` — plugin-installed skills live elsewhere and may
     register under a namespaced name). Not registered → flag it with the
     fix: install the skill from **its own source** (its README or plugin
     marketplace), reload the session, re-run `/factory-init`. Never offer
     to copy skill files from another project — the factory does not
     redistribute third-party skills.
   - Config has **no Design-skill section** but a design-oriented skill is
     registered (or present in `.claude/skills/`) → offer to add the section
     with the exact registered name.
4. **Stamp.** After applying the accepted changes, set the config's
   `factory version:` line (add it if absent) to the value in
   `.claude/factory/VERSION`. No `VERSION` file → leave the stamp alone.
5. **Report** (feeds §4): sections added / skipped / left alone, skill
   verification result, plus the standing reminders — reload the session if
   any agent/skill files changed since session start; commit `config.md`.

### 2b. GENERATE mode — no `config.md` yet

Copy `config.template.md` → `config.md` and fill the placeholders
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
- **Design skill:** check the session's registered skills and `Glob`
  `.claude/skills/*/SKILL.md`; if a design-oriented skill exists, propose it
  (record the exact registered name — plugin skills may be namespaced), else
  delete the section. If the user wants one that isn't installed, point them
  at the skill's own source (README / plugin marketplace) — the factory never
  redistributes third-party skills.
- **Factory version:** fill `{{FACTORY_VERSION}}` from
  `.claude/factory/VERSION`; delete the stamp line if that file is absent.
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
      — or, in sync mode: config synced to v{X} (N sections added, M skipped)
- [x] docs/tickets/ ready · .claude/worktrees gitignored
- [ ] SESSION RELOAD REQUIRED before first /feature   ← if applicable
Next: run `/feature <your first request>` (or `/feature lane:hotfix <tiny fix>`).
```

Anything you could not detect or verify goes in the report as an explicit
open item — never silently assume.
