---
name: create-pr
description: >-
  Use when the user asks to open, create, or update a pull request in a
  project that has the agent factory installed. Builds the PR title and
  description in the factory's standard format from
  .claude/factory/conventions.md §2, with real verification results — so
  hand-opened PRs match factory-opened ones exactly. Not used by factory
  subagents (senior-dev reads conventions.md directly).
---

# Standardized pull request

Open (or update) a PR whose title and body follow the factory convention, so
every PR in the project reads the same regardless of who authored it.

## Procedure

1. **Load the convention.** Read `.claude/factory/conventions.md` §2
   (authoritative) and `.claude/factory/config.md` (default branch, PR tool,
   branch naming).
2. **Establish the change set.** Confirm the branch, that it's pushed (push
   it if not), and read the full diff vs the default branch
   (`git diff <default>...HEAD`, `git log <default>..HEAD --oneline`) — the
   description is written from the *actual* diff, not from memory.
3. **Title:** the conventional-commit line the squash-merge should produce —
   `type(scope): subject`, imperative, ≤72 chars.
4. **Body:** fill the template from conventions.md §2 exactly (Summary /
   Changes / Ticket / Verification / Screenshots / Notes for the reviewer):
   - **Ticket:** link `docs/tickets/{id}/` if one exists for this branch
     (match the branch name against ticket folders); otherwise state
     "no ticket (direct change)".
   - **Verification:** run the config's typecheck, lint (changed files),
     relevant tests — and the build if this PR is ready for review — and
     report the **actual results**. Never submit checked boxes you didn't
     run; an unrun check stays unchecked with a reason.
   - **Screenshots:** for UI changes, remind the user to attach (or capture
     via an available browser tool) — don't fabricate.
5. **Trailers:** append any PR-body trailer the environment requires (e.g. a
   generated-with attribution line) at the very end.
6. **Create** with `gh pr create` (or update an existing PR's body with
   `gh pr edit`), then report the URL and the verification summary.

## Notes

- Updating after new commits: refresh Changes and Verification rather than
  appending "updates" paragraphs — the body always describes the PR's
  current state.
- If the diff is too large to describe honestly in ~10 Changes bullets, say
  so and suggest splitting before opening.
