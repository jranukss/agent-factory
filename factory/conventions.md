# Git Conventions — commits & pull requests (project-agnostic)

The **single source of truth** for how anything in this repo gets committed
and how every PR is described — used by the `senior-dev` factory agent (which
reads this file directly) and by the `commit` / `create-pr` skills (for work
done outside the factory). One format everywhere, whoever authored the change.

Project-specific values (default branch, branch naming, PR tool, any
co-author/trailer requirements) come from `.claude/factory/config.md` and the
environment; this file defines the **format**.

---

## 1. Commit messages — Conventional Commits

```
<type>(<scope>): <subject>

<body — optional>

<footer — optional>
```

**Type** (exactly one):

| type       | use for                                                   |
|------------|-----------------------------------------------------------|
| `feat`     | new user-visible capability                               |
| `fix`      | bug fix                                                   |
| `refactor` | code change that neither fixes a bug nor adds a feature   |
| `test`     | adding or correcting tests only                           |
| `docs`     | documentation only                                        |
| `chore`    | tooling, config, dependencies, cleanup                    |
| `perf`     | performance improvement                                   |
| `ci`       | CI/CD configuration                                       |

**Scope** — the feature or area touched (`dashboard`, `accounts`, `factory`).
Use the ticket's feature area, not the ticket id. Omit only when the change is
truly global.

**Subject** — imperative mood ("add", not "added"/"adds"), ≤ 72 characters,
no trailing period, says *what* the change does:

```
feat(budgets): add date-range selector to budget form
fix(dashboard): show account balances with 2 decimals
```

**Body** — required when the *why* isn't obvious from the subject. Wrap at
~72 chars. Explain motivation and consequences, not a file-by-file replay.

**Footer** — in order, when applicable:

```
Ticket: docs/tickets/{id}
Refs: #<issue or PR number>
<any co-author / attribution trailer the environment requires>
```

**Rules**

- **One logical change per commit.** Never mix unrelated changes; if the diff
  contains two stories, make two commits. Never `git add -A` blind — stage
  the files that belong to the message.
- Fix-loop commits reference the finding:
  `fix(budgets): clamp defaultViewYear to future-min (review #2)`.
- Never commit secrets, `.env*` files, or generated noise.
- Never amend or force-push shared history; add a new commit instead.

---

## 2. Pull request format

**Title** = the conventional-commit line the squash-merge will produce:
`<type>(<scope>): <subject>` — same rules as §1.

**Body** — this exact template, sections in this order; delete a section only
when genuinely empty (and keep Summary, Verification always):

```markdown
## Summary
<2–4 sentences: what this delivers and why. User-facing outcome first.>

## Changes
- <bullet per meaningful change, grouped by area — not a file list>

## Ticket
- Ticket: `docs/tickets/{id}/` (spec → plan → review artifacts inside)
- Mockup: <Artifact URL, if a Full-lane ticket>

## Verification
- [ ] typecheck: <result>
- [ ] lint (changed files): <result>
- [ ] tests: <n passed / details>
- [ ] build: <result>
<manual checks performed, if any>

## Screenshots
<before/after for any UI change; omit section for non-UI changes>

## Notes for the reviewer
<risk areas, decisions made (reversible ones + where recorded), anything
deliberately out of scope; omit if none>
```

**Rules**

- The Verification section reports **actual results** ("18/18 pass"), never
  bare checked boxes. An unchecked box states why (pre-existing failure,
  environment limit).
- Every factory PR links its ticket folder; a non-factory PR links its issue
  or states "no ticket (direct change)".
- Keep the PR reviewable: if Changes needs more than ~10 bullets, the PR is
  probably too big — say so and consider splitting.
- Append any PR-body trailer the environment requires (e.g. a generated-with
  attribution line) at the very end.
