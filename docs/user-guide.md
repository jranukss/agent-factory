# User Guide

*Day-to-day usage. For architecture and concepts, see
[how-it-works.md](how-it-works.md). For installation and distribution, see
the [README](../README.md) and [EXPORT.md](../EXPORT.md).*

---

## 1. First-time setup in a project

1. Get the factory
   (`git clone --depth 1 https://github.com/jranukss/agent-factory`) and run
   the installer:
   `.\install.ps1 -Target <project>` (Windows) or `./install.sh <project>`.
2. **Reload the Claude Code session** — agents register at session start;
   skipping this is the #1 cause of "agent not found".
3. Run **`/factory-init`**. It detects your commands from `package.json`,
   generates `.claude/factory/config.md`, scaffolds `docs/tickets/`, and
   reports anything missing. If the project has no `CLAUDE.md`, run the
   **`factory-docs`** skill first ("prepare this project for the factory") —
   the factory needs a standards doc to enforce.
4. Commit the installed files and the generated config to the project.
5. Smoke-test with one tiny ticket: `/feature lane:hotfix <a trivial fix>`.

## 2. Starting work

```
/feature add a monthly budget summary to the dashboard
/feature lane:hotfix typo on the sign-in button
/feature                          ← no arguments = resume the in-progress ticket
```

- Naming a lane (`lane:full`, `lane:lite`, `lane:hotfix`) skips the scope
  recommendation. Otherwise the product-owner sizes the request and
  recommends one — including "this already exists, close it" when true.
- One ticket at a time is the default. If another ticket is mid-implementation,
  the orchestrator will offer to queue the new one (it can still be scoped,
  specced, and planned — it just won't touch code yet).

## 3. What you'll be asked, and how to answer well

| Prompt | What to check before approving |
|---|---|
| **Intake questions** | These shape the spec — answer precisely; "whatever you think" pushes the decision into the acceptance criteria unexamined. |
| **Spec approval** | Read the *acceptance criteria*, not the prose: they are what QA will test and what the reviewer holds the diff to. Missing criterion = it won't be built. |
| **Mockup approval** | The Artifact link renders the real mockup. Check states (empty/error/loading), not just the happy screen. Request changes freely — this is the cheapest moment to change direction. |
| **Plan approval** | The most important gate. Check: the approach, the file list (it becomes the scope contract), the test plan, and any decision flagged in the plan. Hard-to-reverse calls surface here. |
| **Finding triage** | When the orchestrator asks "fix now / defer / accept" about a review or QA finding, a deferral can become a follow-up ticket — say so. |
| **Merge** | Yours, always. The report links the PR, review verdict, and QA result. |
| **Learning proposal** | A suggested one-paragraph standards amendment after merge. Approve only what you want *enforced on every future ticket* — this edits your CLAUDE.md. |

Answering "Request changes" at any gate loops the owning agent with your
notes (bounded at 3 rounds, then the orchestrator escalates options to you).

## 4. While it runs

- You can walk away. If notifications are configured (config.md →
  Notifications), you're pinged when a gate needs you.
- Progress lives in `docs/tickets/{id}/STATUS.md` — phase, log, artifacts.
- Session died, laptop restarted, context compacted? Just run `/feature`.
  The state machine resumes from the last recorded phase; a half-finished
  implementation resumes in its existing worktree.
- Implementation happens in `.claude/worktrees/{id}` on branch `feat/{id}` —
  your checkout stays clean. Avoid editing the same feature in your main
  checkout while a ticket is mid-implementation.
- At heavy steps the orchestrator checks real context usage and, past the
  threshold in config.md (→ Context checkpoint), asks "continue vs stop for
  a fresh window". Stopping is lossless — STATUS.md is finalized and a bare
  `/feature` in a new session resumes exactly where it left off.

## 5. Review, QA, and fix loops

After the PR opens, the code-reviewer and qa-lead run in parallel. Then:

- Findings default to **fixed** — all severities. Skips require a recorded
  reason; judgment calls come to you.
- Live QA (Full lane, and Lite if configured) drives the running app in a
  real Playwright browser against the qa-lead's written plan, using the test
  accounts documented in your QA accounts doc. Failures loop back to the
  senior-dev; re-runs execute only the failed scenarios.
- Every loop stops after 3 iterations and asks you how to proceed — nothing
  ping-pongs forever.

## 6. Merge and after

Merge the PR yourself (squash recommended — the PR title is the
conventional-commit line). Then tell the factory (`/feature` resumes at the
merge-check) and it will: verify the merge, remove the worktree, delete the
branch, mark the ticket `MERGED`, log final cost, propose any learning, and
offer the next ROADMAP phase if the work was split.

## 7. Commits and PRs outside the factory

Hand-authored work uses the same formats via two skills:

- **`commit`** — "commit this": groups the diff into logical Conventional
  Commits per `factory/conventions.md`.
- **`create-pr`** — "open a PR": builds the standard PR description with real
  verification results.

The senior-dev agent reads the same conventions file, so factory and manual
output are indistinguishable in history.

## 8. Tracking cost

- Each ticket's `STATUS.md` gets `## Cost` entries at READY_TO_MERGE and
  MERGED (token totals + estimated $, via ccusage).
- Session-level: `npx ccusage@latest session` · daily: `... daily` ·
  plan-limit windows: `... blocks`. In-session: `/usage` (subscription) or
  `/cost` (API billing).
- Per-agent breakdowns need OpenTelemetry: set
  `CLAUDE_CODE_ENABLE_TELEMETRY=1`, an OTLP endpoint, and
  `OTEL_LOG_TOOL_DETAILS=1` (without it, custom agent names are redacted to
  "custom"). See the [Claude Code monitoring docs](https://code.claude.com/docs/en/monitoring-usage).

## 9. Troubleshooting

| Symptom | Cause → fix |
|---|---|
| "Agent type 'product-owner' not found" | Agents load at session start → reload the session. |
| `/feature` resumes the wrong ticket | Several in-flight tickets → it asks; pick, or close stale ones (set `phase: CLOSED` + reason, or let the orchestrator do it). |
| Worktree already exists error | Interrupted run → resume normally; the senior-dev reuses it. Manual cleanup: `git worktree remove .claude/worktrees/{id} --force`. |
| Dev server port in use during QA | A stale server → the qa-runner kills and restarts per config's platform notes; if it can't, free the port yourself and resume. |
| Reviewer flags something CLAUDE.md allows | Your standards doc is ambiguous or self-contradictory there → accept-with-reason in triage, then let the learning gate (or the `factory-docs` audit) fix the doc. |
| Agent returns prose without a STATUS line | Handled: the orchestrator retries once with the protocol reminder, then asks you. |
| ccusage not installed | Cost entries log "n/a" — harmless. `npm i -g ccusage` or rely on `npx`. |
| Live QA can't log in | Missing/undocumented test accounts → fill `docs/qa/test-accounts.md` (the `factory-docs` skill scaffolds it) and ensure the seed command creates them. |

## 10. Updating the factory

Re-run the installer from a newer tagged version of the factory repo — it
overwrites agents/commands/protocol/skills but never your `config.md`. Check
the factory CHANGELOG for new config sections, run `/factory-init` to
validate, reload the session. In-flight tickets should finish on the version
they started on.
