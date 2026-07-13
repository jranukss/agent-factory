---
name: factory-docs
description: >-
  Use when setting up or upgrading a project's markdown documentation to work
  with the agent factory — generating a standards doc (CLAUDE.md) with the
  section structure the factory's role-map expects, auditing an existing one
  for gaps, or scaffolding the supporting docs (docs/tickets/README.md, QA
  test-accounts doc). Triggers: "prepare this project for the factory",
  "generate the standards doc", "audit CLAUDE.md for the factory",
  "factory docs".
---

# Factory-ready project documentation

The factory's agents are generic: every project-specific rule they enforce
comes from the project's own markdown docs. This skill produces those docs in
the shape the factory consumes — so `/factory-init`'s role-map has real
sections to point at, the tech-lead can digest rules per ticket, and the
code-reviewer has authoritative text to cite.

**Prime directive: extract, don't invent.** A standards doc must describe how
the codebase *actually* works today. Derive every rule from the code (and
from the user, for intentions the code can't show). Never import conventions
from other projects or from generic best practice without evidence in this
repo — a rule the code contradicts is worse than no rule.

## Mode 1 — Generate a standards doc (no CLAUDE.md yet)

1. **Study the codebase**: stack and versions (package manifest, lockfile,
   config files), directory layout, one or two of the most complete features
   end-to-end (these become the "canonical reference feature"), test layout
   and runner, error-handling / validation / state patterns actually in use.
2. **Interview for what code can't show** (a few AskUserQuestion rounds max):
   which feature is the best exemplar, hard rules vs habits, what reviewers
   should block on.
3. **Write `CLAUDE.md`** with this backbone — these are the sections the
   factory's role-map and config template reference; keep the exact heading
   names where possible:

   ```markdown
   # {Project} — Standards
   ## Project Overview          ← what the app is; the domain vocabulary
   ## Tech Stack                ← frameworks + versions + key libraries, one line each
   ## Project Structure         ← annotated directory tree
   ## Feature Development Rules ← the vertical-slice recipe, layer by layer,
                                  each with rules + a short canonical example
   ## Component Architecture    ← layers, import rules, reusable components list
   ## Data & State Rules        ← identity, ownership, audit, caching rules
   ## Validation Rules          ← where schemas live, client/server split
   ## Testing Rules             ← layers, locations, naming, what NOT to test
   ```

   Rules must be **citable and checkable**: concrete, imperative, with the
   pattern shown ("Services return `Result` types; never throw across the
   boundary"), not aspirational ("write clean code"). If the project has few
   real conventions yet, write a *short* honest doc — the factory works with
   thin standards; it breaks on wrong ones.
4. **Name the canonical reference feature** explicitly — the factory's config
   points agents at it as the structural yardstick.

## Mode 2 — Audit an existing standards doc

1. Read `CLAUDE.md` and `.claude/factory/config.md`'s role-map (if present).
2. Check: every role-map section reference resolves to a real heading; each
   backbone section above exists (or an equivalent under another name — then
   recommend updating the role map, not renaming the user's doc); rules
   contradicted by the current code (**flag these hard** — factory reviews
   will misfire on them, this is how factories rot); missing "what NOT to do"
   guidance in testing/review-sensitive areas.
3. Report gaps as a prioritized list; apply fixes only on request — the
   standards doc is the user's, and standards changes deserve their scrutiny
   (same principle as the factory's post-merge learning gate).

## Mode 3 — Scaffold the supporting docs

Create when missing (skip silently when present):

- **`docs/tickets/README.md`** — one paragraph: each subfolder is one factory
  ticket; layout and state machine defined in `.claude/factory/protocol.md`;
  project specifics in `.claude/factory/config.md`; start/resume with
  `/feature`.
- **`docs/qa/test-accounts.md`** — skeleton table (label · email · purpose ·
  how seeded) + a note that live QA reads this file. **Placeholders only —
  never write real credentials**; tell the user to fill values and how the
  seed command should create them.
- Confirm `.claude/worktrees` is gitignored; append it if not.

## After any mode

Summarize what was written/changed, and remind: if `.claude/factory/config.md`
already exists, re-run `/factory-init` so the role-map section names are
revalidated against the updated doc.
