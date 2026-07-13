# Factory Config — {{PROJECT_NAME}}

<!--
  TEMPLATE — copy to `.claude/factory/config.md` in the target project and fill
  every {{placeholder}}. `/factory-init` does this for you (and detects most
  values from package.json / the repo). This is the ONE project-specific file
  the generic factory agents read. Pair it with `.claude/factory/protocol.md`
  (the generic contract — do not edit that per project).
-->

**Precedence:** the user's live instructions win over everything. For coding
*conventions/rules*, the standards docs below are authoritative. For *commands
and paths*, this file is authoritative.

---

## Standards  (read first; authoritative for conventions)

- `{{STANDARDS_DOC}}` <!-- usually CLAUDE.md at the repo root -->
- `{{EXTRA_DOCS}}` <!-- e.g. docs/**/*.md — QA accounts, architecture notes; delete if none -->

> Canonical reference feature: `{{REFERENCE_FEATURE}}` <!-- the vertical slice
> agents mirror when in doubt; delete if the project has none -->

---

## Commands  (use verbatim; never assume)

| purpose        | command                       |
|----------------|-------------------------------|
| typecheck      | `{{TYPECHECK_CMD}}`           |
| lint           | `{{LINT_CMD}}`                |
| test (all)     | `{{TEST_CMD}}`                |
| test (file)    | `{{TEST_FILE_CMD}}`           |
| build          | `{{BUILD_CMD}}`               |
| dev server     | `{{DEV_CMD}}`  (serves {{DEV_URL}}) |
| seed test data | `{{SEED_CMD}}` <!-- delete if none --> |

**Verification contract (senior-dev):** typecheck + lint (changed files) +
relevant tests on every push; **build** at least once before the PR is handed
to review (build catches failure classes the others miss). Whole-project
checks: attribute only errors in changed files to the ticket; note
pre-existing errors separately.

---

## Paths

| what           | path                             |
|----------------|----------------------------------|
| tickets        | `docs/tickets`                   |
| design mockups | `docs/tickets/{id}/design`       |
| source root    | `{{SRC_ROOT}}`                   |
| worktrees      | `.claude/worktrees` (gitignored) |

---

## Workflow

- default branch: `{{DEFAULT_BRANCH}}`
- PR tool: `gh`
- branch naming: `feat/{id}` or `fix/{id}`
- implementation happens in an isolated git worktree under
  `.claude/worktrees/{id}`; **reuse an existing worktree on resume** (never
  recreate), and sync with the default branch before opening the PR and on
  every fix-loop push.
- platform notes: {{PLATFORM_NOTES}}
  <!-- e.g. "Windows host; shell is Git Bash; free port 3000 with
       `npx kill-port 3000` (not `kill`)". Delete if none. -->

---

## Role → standards sections  (scoped reading; controls context cost)

Agents read only the sections relevant to their role. Downstream agents prefer
the tech-lead's `standards-digest.md` over the full doc. The **code-reviewer**
always reads the full authoritative standards doc (review quality must not
rest on a lossy digest).

| role          | reads                                                        |
|---------------|--------------------------------------------------------------|
| product-owner | {{PO_SECTIONS}}        <!-- product overview, feature intro --> |
| ux-designer   | {{UX_SECTIONS}}        <!-- component architecture, reusable components --> |
| tech-lead     | {{TL_SECTIONS}}        <!-- structure, feature rules, testing rules --> |
| senior-dev    | `standards-digest.md` first; then {{DEV_SECTIONS}} as the plan touches them |
| code-reviewer | **ALL standards docs** (authoritative)                        |
| qa-lead       | {{QA_LEAD_SECTIONS}}   <!-- testing rules, routes, feature behavior --> |
| qa-runner     | {{QA_RUN_SECTIONS}}    <!-- routes, test accounts doc -->     |

---

## Roles → models

Advisory table; agent frontmatter is the fallback. The orchestrator passes the
model override on each Task call when the harness supports it.

| role          | model  | rationale                                    |
|---------------|--------|----------------------------------------------|
| product-owner | sonnet | sizing + spec writing; opus not required     |
| ux-designer   | opus   | design quality is worth it                   |
| tech-lead     | opus   | plan quality compounds downstream — never cut here |
| senior-dev    | opus   | the diff is the product                      |
| code-reviewer | opus   | judgment-heavy                               |
| qa-lead       | opus   | scenario enumeration is judgment-heavy       |
| qa-runner     | sonnet | mechanical browser-driving; cheapest that works |

---

## Gate policy  (modes: ask · auto · folded — see protocol §7)

| # | gate                        | full   | lite                | hotfix |
|---|-----------------------------|--------|---------------------|--------|
| 1 | lane / split                | auto¹  | auto¹               | —      |
| 2 | answer intake               | ask    | ask                 | —      |
| 3 | approve spec                | ask    | folded → gate 5     | —      |
| 4 | approve mockup              | ask    | — (no design)       | —      |
| 5 | approve plan                | ask    | ask                 | ask    |
| 6 | merge                       | ask    | ask                 | ask    |
| 7 | post-merge learning         | ask²   | ask²                | ask²   |

¹ a ROADMAP split always asks. ² only when there is a proposal.

## Lanes

- **Full** — user-facing work with a real UI surface: every phase.
- **Lite** — small / low-risk / backend-only: skips DESIGN. QA_RUNNING:
  {{LITE_QA}} <!-- "yes" | "no" | "qa-lead plan only, no live run" -->
- **Hotfix** — tiny, obvious fixes: task → plan (short) → gate 5 → implement →
  review → merge. No PO, no design, no live QA.

The product-owner recommends the lane at the scope pass; a lane named by the
user in the request wins without a scope pass.

---

## Design skill  (optional)

- skill name: `{{DESIGN_SKILL}}` <!-- e.g. "impeccable"; delete this section if
  the project has no design skill — ux-designer then designs unaided -->

## Notifications  (optional)

- gate notification: {{NOTIFY_MECHANISM}}
  <!-- e.g. "Claude Code Notification hook (configured in settings.json)" or
       "PushNotification tool" or "none". When set, the orchestrator pings on
       every `ask` gate so the user can walk away between gates. -->

## Context checkpoint  (protocol §10)

- threshold: 60
  <!-- % of the context window at which the orchestrator, at heavy checkpoints
       (post-IMPLEMENTING, each fix-loop iteration, READY_TO_MERGE), offers to
       stop for a fresh session (lossless resume via STATUS.md). "off"
       disables checkpoints. Keep below ~75 — auto-compaction fires near 80%. -->
