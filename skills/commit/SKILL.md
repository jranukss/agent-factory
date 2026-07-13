---
name: commit
description: >-
  Use when the user asks to commit changes (commit, "save this", "check this
  in") in a project that has the agent factory installed. Produces
  standardized Conventional Commits per .claude/factory/conventions.md —
  groups the working diff into logical commits, stages precisely, and writes
  compliant messages. Not for opening PRs (use create-pr) and not used by
  factory subagents (senior-dev reads conventions.md directly).
---

# Standardized commit

Produce commits that follow the factory's shared convention exactly, so
factory-authored and hand-authored history are indistinguishable.

## Procedure

1. **Load the convention.** Read `.claude/factory/conventions.md` §1. It is
   authoritative — if this skill and that file ever disagree, the file wins.
2. **Survey the working tree.** `git status` + `git diff` (and
   `git diff --staged` if something is already staged). Understand what
   changed and *why* before writing anything.
3. **Group into logical commits.** One logical change per commit. If the diff
   contains unrelated changes (e.g. a feature + a drive-by fix + formatting
   noise), plan multiple commits and say so. Never `git add -A` blind — stage
   exactly the files that belong to each message (`git add <paths>`; use
   `git add -p` when a single file mixes concerns).
4. **Write the message(s)** per the convention: `type(scope): subject`
   (imperative, ≤72 chars, no period), body for non-obvious *why*, footer with
   `Ticket:` / `Refs:` when applicable, plus any trailer the environment
   requires (check the project instructions for a required co-author line).
5. **Safety checks before each commit:**
   - nothing staged that looks like a secret, `.env*`, credentials, or large
     generated artifacts — stop and ask if found;
   - you are not on the default branch unless the user said so — offer a
     branch first;
   - pre-commit hooks are respected: if a hook fails, fix the cause; never
     `--no-verify`.
6. **Commit** and report: the commit hash(es), each message's first line, and
   anything deliberately left uncommitted (and why).

## Notes

- If the changes belong to a factory ticket (a `docs/tickets/{id}/` folder
  references them), include the `Ticket:` footer.
- If the user asks for one commit but the diff is clearly two stories,
  recommend the split once; if they insist, one commit with an honest
  multi-area message beats a misleading narrow one.
- Amending: only when the user explicitly asks and the commit is unpushed.
