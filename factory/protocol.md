# Factory Protocol v2 (project-agnostic)

This is the shared contract that every factory agent and the `/feature`
orchestrator follow. It contains **no project-specific rules** — those live in
`.claude/factory/config.md` (operations: commands, paths, models, gates) and
the project's standards doc(s) named there (coding conventions). Read this
alongside `config.md` at the start of every run.

The factory drives a work item ("ticket") from an idea to a **merged** pull
request through a team of specialist subagents that hand off via **files on
disk**, pausing at **human gates** whose interactivity is configurable.

> **Registration note:** Claude Code loads agent definitions at **session
> start**. After adding or editing a factory agent (`.claude/agents/*.md`),
> **reload the session** before the orchestrator can launch it as a
> `subagent_type`. Because every ticket's state lives in `STATUS.md`, you can
> reload mid-run and resume with `/feature` (no args).

---

## 1. The purity rule (why handoffs are files)

Subagents run in **isolated context** — they do not share the orchestrator's
conversation. Therefore:

- **Subagents are pure:** they *read files*, *write files*, and *return text*.
  They never publish Artifacts, never prompt the user directly.
  - **One documented exception:** the **ux-designer** may invoke the design
    Skill named in `config.md` (if the project has one) to raise mockup
    quality. It still never publishes Artifacts or prompts the user — the
    orchestrator publishes its `design/mockup.html` as the Artifact. No other
    subagent gets Skill access.
  - **One capability exception:** the **qa-runner** drives the Playwright MCP
    browser tools — that is its job, not a purity violation.
- **The orchestrator (main session) owns everything interactive:** asking the
  user (`AskUserQuestion`), publishing Artifacts, sending gate notifications,
  and updating `STATUS.md`. It coordinates; it never plans, designs, or writes
  application code itself.
- **All handoff state is on disk** in the ticket folder, so a run is resumable:
  the orchestrator reads `STATUS.md`, runs the next step, and stops at the gate.

---

## 2. The ticket folder

Each ticket is a folder under the configured `tickets` path
(`docs/tickets/{id}/` by default). `{id}` is a short kebab-case slug derived
from the task (the orchestrator ensures uniqueness).

```
docs/tickets/{id}/
  task.md              # the raw request (captured by the orchestrator)
  STATUS.md            # state machine — drives resumability (see §3)
  ROADMAP.md           # only when the PO split the work into phases
  00-intake.md         # clarifying Q&A                 (product-owner)
  01-spec.md           # spec + acceptance criteria     (product-owner)
  02-design.md         # UX spec + Artifact URL         (ux-designer, Full lane)
  design/mockup.html   # mockup source                  (ux-designer, Full lane)
  03-plan.md           # implementation plan            (tech-lead)
  standards-digest.md  # distilled rules this ticket touches (tech-lead)
  04-review.md         # review findings + verdict      (code-reviewer)
  05-qa-plan.md        # UAT plan                       (qa-lead)
  05-qa-report.md      # live UAT results               (qa-runner)
```

Each role **reads the prior artifacts** it needs and **appends its own**. It
never rewrites another role's artifact (except an agent re-invoked to revise
its *own* output — e.g. tech-lead revising `03-plan.md`).

Ticket folders are **committed to git** together with the code they describe —
they are the audit trail.

---

## 3. STATUS.md — the state machine

`STATUS.md` is the single source of truth for where a ticket is. **Only the
orchestrator writes it**, after every transition. Format:

```markdown
# STATUS — {id}
task: {one-line summary}
lane: full | lite | hotfix    # set at the scope gate (or from the user's request)
phase: PLANNING               # current phase (see below)
pr: {url or "-"}
updated: {ISO-8601}

## Phase log
- {ISO}  created
- {ISO}  gate 1 (auto): lane = lite per PO recommendation
- {ISO}  tech-lead → 03-plan.md + standards-digest.md
- {ISO}  gate 5: plan approved
- {ISO}  senior-dev → PR #NN opened
- {ISO}  code-reviewer → 04-review.md (1 warning) ∥ qa-lead → 05-qa-plan.md
- {ISO}  fix-loop iter 1 → warning fixed; delta re-review clean
- {ISO}  qa-runner → 05-qa-report.md (all pass)
- {ISO}  user merged PR #NN; post-merge pass: worktree+branch cleaned

## Artifacts
- [x] 03-plan.md
- [x] standards-digest.md
- [x] PR: {url}
- [x] 04-review.md
- [x] 05-qa-plan.md / 05-qa-report.md

## Cost
- {ISO}  session est.: {tokens in/out, est. $ from ccusage} · through {phase}
```

**Phases:**

```
SCOPING → INTAKE → SPEC → DESIGN → PLANNING → PLAN_REVIEW → IMPLEMENTING
        → REVIEWING → FIXING → QA_RUNNING → READY_TO_MERGE → MERGED
```

- `REVIEWING` covers **both** the code review and the qa-lead's UAT-plan
  writing — they run in parallel (they are independent reads of the same PR).
- **Lane coverage:** Full runs every phase; **Lite** skips `DESIGN`;
  **Hotfix** skips `SCOPING`/`INTAKE`/`SPEC`/`DESIGN` and (by config default)
  `QA_RUNNING`. Whether Lite runs QA is set in config's lane table.
- **Terminal phases: `MERGED` and `CLOSED`.** `CLOSED` carries a
  `closed_reason:` line (e.g. "already implemented", "abandoned by user").
  Nothing else is terminal — in particular **`READY_TO_MERGE` is resumable**
  (resuming it runs the merge-check / post-merge pass, §8).

To **resume**, the orchestrator reads `phase` and continues from there. A
ticket counts as in-progress iff its phase is **not** in the terminal set.

---

## 4. Agent return protocol

Every subagent ends its returned message with a single **status line**:

- `STATUS: COMPLETE` — the step is done; the artifact(s) are written. The
  message also states which files it wrote.
- `STATUS: NEEDS_INPUT` — the agent hit a gray area it must not decide itself
  (§5). Followed by a **QUESTIONS block**; the agent writes no further
  artifacts until answered.
- `STATUS: PLAN_ISSUE` — (senior-dev only) implementation revealed the
  approved plan is wrong or infeasible. Followed by a short explanation **and
  the state of the worktree** (what partial work exists). The orchestrator
  routes back to the tech-lead.
- `STATUS: BLOCKED` — the agent cannot proceed for an operational reason (a
  command failed, a precondition is missing). Followed by the reason.

**Malformed-return fallback (orchestrator rule):** if an agent returns with no
recognizable `STATUS:` line, or the Task call itself fails, treat it as
`BLOCKED`: re-invoke **once** with a reminder of this return protocol appended
to the prompt; if it happens again, surface to the user via `AskUserQuestion`
(retry / skip step / abandon ticket). Never guess a status from prose.

**QUESTIONS block** (parsed by the orchestrator to build `AskUserQuestion`):

```
QUESTIONS:
- q: <the decision, phrased as a question>
  header: <≤12-char label>
  options:
    - label: <recommended option>   # put the recommended one first
      detail: <what it means / trade-off>
    - label: <alternative>
      detail: <...>
```

The orchestrator presents these via `AskUserQuestion` — **chunked**: at most 4
questions per call and at most 4 options per question (the tool's limits); more
questions means more calls. It appends the answers to the relevant ticket
artifact and delivers them to the agent — by **continuing the same agent**
where the harness supports it (preferred: no cold start), else by re-invoking
with the answers in the artifact.

---

## 5. Questioning threshold — when to ask vs decide

Agents must **stop and ask** (via `STATUS: NEEDS_INPUT`) on:

- **What to build** — ambiguous requirements, unclear scope, UX intent.
- **Hard-to-reverse technical decisions** — data model / schema shape, a
  public API or contract, adding a new dependency.

Agents **decide themselves and note it** in their artifact for:

- **Reversible implementation details** — naming, file layout, internal
  helpers, test structure, private function shapes.

When in doubt about reversibility, ask. Because agents can always raise
`NEEDS_INPUT`, relaxing a gate to `auto` (§7) never silences a real question —
it only removes rubber-stamp confirmations.

---

## 6. Loops — all bounded

Every loop is bounded at **3 iterations**; hitting the bound stops the loop and
escalates to the user via `AskUserQuestion` (continue anyway / take over
manually / accept as-is / abandon). Loop iterations are logged in `STATUS.md`.

- **Intake loop** — `NEEDS_INPUT` from product-owner → answers → continue.
- **Revision loops** — spec (Gate 3), design (Gate 4), and plan (Gate 5)
  "request changes" each re-invoke their author with the notes.
- **Review fix loop** — findings in `04-review.md` re-invoke **senior-dev**.
  The default is to fix **every** finding — blocker, warning, **and** nit. A
  finding is skipped only when it is **genuinely no-value**: purely subjective
  with no correctness/clarity/a11y/perf benefit; an out-of-scope project-wide
  change that a one-off would make inconsistent (belongs in its own ticket); or
  a false-premise flag. Every skip gets a one-line reason under
  `## Accepted / deferred` in `04-review.md`. When "is this worth fixing?" is a
  real value/scope judgment, the orchestrator brokers it to the user.
  - **Delta re-review:** on fix-loop iteration N ≥ 2, the code-reviewer reviews
    only **the diff since its last review plus its prior findings** — not the
    full rubric over the whole PR again.
- **QA fix loop** — failures in `05-qa-report.md` re-invoke senior-dev; the
  qa-runner then re-executes **only the failed/blocked scenarios**, not the
  whole plan.
- **Re-plan loop** — `PLAN_ISSUE` → tech-lead revises `03-plan.md` **aware of
  the worktree's partial state** (the orchestrator passes the worktree path and
  senior-dev's description of what exists); the plan gate re-runs; the revised
  plan states whether the partial work is kept or reset; dev resumes.

---

## 7. Human gates & gate policy

Gates are where a human decides. **How interactive each gate is** comes from
the **gate policy table in `config.md`**. Modes:

- **`ask`** — `AskUserQuestion`; the pipeline blocks until answered.
- **`auto`** — accept the responsible agent's recommendation, log the decision
  in `STATUS.md`, and mention it in the next user-facing message. An agent's
  `NEEDS_INPUT` always overrides `auto` (real questions still stop the line).
- **`folded`** — don't ask now; batch this gate's summary into the next `ask`
  gate (e.g. show spec + plan together at the plan gate on the Lite lane).

Full gate list, in order:

| # | Gate | Default mode |
|---|------|-------------|
| 1 | lane / split approval | `auto` (but a ROADMAP split **always asks**) |
| 2 | answer intake questions | `ask` (irreducible) |
| 3 | approve spec | Full: `ask` · Lite: `folded` into Gate 5 |
| 4 | approve mockup | `ask` (Full lane only) |
| 5 | approve plan | `ask` — **never set to auto**; this protects hard-to-reverse decisions |
| 6 | merge | `ask` (manual merge is fine) |
| 7 | post-merge learning proposal | `ask`, and only when there is a proposal |

**Notifications:** if the project configures a notification mechanism
(config.md → Notifications), the orchestrator fires it whenever a gate enters
`ask` state, so the user can walk away between gates. Never advance a phase
past an `ask` gate without an explicit user answer.

---

## 8. End of life: merge-check, post-merge pass, closing

The pipeline does not go dark at `READY_TO_MERGE`:

1. **Merge-check.** On resume (or when the user says they merged), the
   orchestrator verifies with the PR tool (`gh pr view --json state,mergedAt`).
2. **Post-merge pass** (a step, not an agent), once merged:
   - remove the ticket's worktree and delete the local + remote branch
     (`git worktree remove`, `git branch -d`, remote branch is usually deleted
     by the merge — verify);
   - set `phase: MERGED`, tick artifacts, append the final `## Cost` entry;
   - **learning capture:** if the ticket surfaced a new convention, a gotcha,
     or a recurring reviewer false-positive, draft a ≤1-paragraph amendment to
     the project's standards doc and run Gate 7 (`ask`) — the user approves any
     standards change; never edit standards silently;
   - **ROADMAP continuation:** if `ROADMAP.md` has a next phase, offer to open
     its ticket (one `AskUserQuestion`), seeding the new `task.md` from the
     roadmap entry.
3. **Closing without merge.** A ticket that ends any other way gets
   `phase: CLOSED` + `closed_reason:`, and the same cleanup (worktree, branch,
   close the PR if one was opened).

---

## 9. Concurrency policy

**Tickets are sequential by default.** At most one ticket may be at
`IMPLEMENTING` or beyond at a time; a second ticket may proceed **only through
`PLANNING`** (no worktree, no branch) while another is in flight. Rationale:
worktrees isolate code, but dev servers, QA ports, review freshness, and merge
order do not compose. If the user explicitly asks to parallelize past this,
warn once about the risks (stale review base, port conflicts) and record their
decision in both tickets' `STATUS.md`.

The user hand-editing the main checkout while a ticket is in `IMPLEMENTING` is
the same hazard — senior-dev syncs with the default branch before opening the
PR and on every fix-loop push (see the agent contract), which contains it.

---

## 10. Context checkpoints

Long orchestrator sessions degrade and eventually auto-compact — a **lossy**
summary. Because every handoff lives on disk (§1–§3), a deliberate restart is
strictly better: a fresh session resumes losslessly from `STATUS.md` with a
bare `/feature`. So the orchestrator checks its own context weight at the
points that bloat it:

- **When:** after senior-dev completes `IMPLEMENTING`; after **each**
  review-fix or QA-fix loop iteration; on entering `READY_TO_MERGE`.
- **How:** run `node .claude/factory/scripts/context-usage.mjs` — it reads the
  session transcript and prints the **real** usage as one JSON line
  (`{"tokens":…,"window":…,"pct":…}`). Compare `pct` to the config's
  **Context checkpoint threshold** (default **60**; auto-compaction triggers
  around ~80%, so 60 leaves room to finish a step and stop cleanly).
- **Over threshold →** `AskUserQuestion`: **continue in this session** vs
  **stop for a fresh window** (recommended option first: stop, when pct ≥ 70;
  continue, below). On **stop**: finish the `STATUS.md` update for the step
  just completed, append a phase-log line
  (`context checkpoint: stopped at NN% for a fresh session`), tell the user to
  reload and run `/feature`, and end the turn — the resume path (§3) does the
  rest.
- **Fallback:** the script reads an undocumented transcript format; if it
  fails, judge by signals instead (a compaction summary present in context,
  ≥2 fix-loop iterations this session, 3+ phases driven this session) and say
  the number is an estimate. **Never block the pipeline on measurement.**
- Config `threshold: off` disables checkpoints.

---

## 11. Cost tracking

At `READY_TO_MERGE` and again at `MERGED`, the orchestrator appends an entry to
the ticket's `## Cost` section using `npx ccusage session --json` (best-effort:
if ccusage is unavailable, log "n/a" and move on — never block on cost
logging). Convention: **one ticket run ≈ one session** where practical, so the
session totals approximate the ticket's cost. Deeper per-agent attribution is
available via OpenTelemetry (see the factory README) but is not a protocol
concern.
