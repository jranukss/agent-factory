# EXPORT.md — Publishing the factory to GitHub & installing it anywhere

The plan for turning this folder into a distributable GitHub repo, keeping it
versioned, and installing/updating it across projects. Phase 1 (copy-based) is
fully supported by what's in this repo today; Phase 2 (Claude Code plugin) is
the polished end-state.

---

## Phase 0 — One-time repo creation (10 minutes)

From this folder (`claude-agent-factory/`):

```bash
git init
git add .
git commit -m "feat: agent factory v2 — portable feature-delivery pipeline"
gh repo create jranukss/claude-agent-factory --private --source . --push
git tag v2.0.0 && git push --tags
```

Recommended repo hygiene from day one:

- **Private first**, public later if you want — nothing in the factory is
  project-specific, but review once before flipping.
- **Semver tags** (`v2.0.0`, `v2.1.0`…): projects pin to a tag, so a factory
  change never surprises a mid-flight ticket.
- **`CHANGELOG.md`**: one line per change, noting which files a project must
  re-copy and whether `config.md` gained new sections (the only file installs
  don't overwrite — config changes need a manual note).
- Keep `chmod +x install.sh` (set `git update-index --chmod=+x install.sh` on
  Windows so the bit survives).

## Phase 1 — Copy-based install (works today)

**New project:**

```bash
git clone --depth 1 --branch v2.0.0 https://github.com/jranukss/claude-agent-factory tmp-factory
tmp-factory/install.sh /path/to/project        # or install.ps1 -Target ... on Windows
rm -rf tmp-factory
```

Then in the project: reload the Claude Code session → `/factory-init` →
commit `.claude/agents`, `.claude/commands`, `.claude/factory`, and
`docs/tickets/` **into the project's repo** (the project owns its installed
copy + config; the factory repo is the upstream).

**Updating a project** to a new factory version: re-run the install script
from the new tag. It overwrites agents/commands/protocol/template but **never
`config.md`**; check the CHANGELOG for "config sections added" notes and port
those by hand (or let `/factory-init` diff-and-report — it detects missing
sections). Then reload the session.

**Why copy, not submodule/subtree:** agents and commands *must* physically
live under the project's `.claude/` for Claude Code to load them, and projects
should be able to hot-patch a local agent without touching upstream. A
submodule adds ceremony for zero loading benefit.

## Phase 2 — Package as a Claude Code plugin (the clean end-state)

Claude Code plugins distribute commands/agents/skills from a repo and load
them **without copying into each project**, with marketplace-style install
(`/plugin`) and updates. Migration steps when you're ready:

1. Add a manifest:
   ```
   .claude-plugin/plugin.json
     { "name": "agent-factory", "version": "2.1.0",
       "description": "Feature-delivery factory: /feature + 7 role agents" }
   ```
2. The repo layout already matches plugin conventions (`commands/`,
   `agents/` at the root) — the main port is **paths**: plugin files must
   reference `${CLAUDE_PLUGIN_ROOT}/factory/protocol.md` instead of
   `.claude/factory/protocol.md`, while `config.md` (per-project by nature)
   stays at the project's `.claude/factory/config.md`. Adjust the "Load the
   contracts" step in each agent + command accordingly.
3. Register a marketplace entry (a repo can serve as its own marketplace via
   `.claude-plugin/marketplace.json`), then in any project:
   `/plugin marketplace add jranukss/claude-agent-factory` →
   `/plugin install agent-factory` → `/factory-init`.
4. Keep the install scripts working through the transition — copy-based and
   plugin installs can coexist (a project uses one or the other).

Trade-off to know: plugin agents/commands update centrally (good for many
projects), but a project can no longer hot-patch its local copy of an agent —
project-specific behavior then belongs **only** in `config.md` + the standards
doc. That's already the factory's design principle, so the migration is
natural once v2 has proven stable across 2–3 projects.

## Rollout checklist per new project

1. `install.sh` / `install.ps1` from a **tagged** version.
2. Reload the Claude Code session.
3. `/factory-init` — fix anything it reports (missing standards doc → run
   `/init` first; missing `gh` auth; Playwright MCP absent → live QA
   unavailable, factory still works through review).
4. Commit the installed files + generated `config.md` to the project.
5. Smoke-test with one **Hotfix-lane** ticket end-to-end before trusting a
   real feature — the factory's own regression check.

## Keeping v1 (CountIt) and v2 straight

CountIt currently runs factory **v1** from its own `.claude/`. Nothing in this
repo touches it. When you're ready to migrate CountIt to v2: run the installer
against the CountIt repo on a **branch**, let it overwrite the v1 agents (the
CountIt-specific `code-reviewer`/`qa-tester` are superseded by the generic
`code-reviewer`/`qa-lead`+`qa-runner` — keep `qa-tester` if you still want the
standalone `/qa` command), port the existing `.claude/factory/config.md`
values into the v2 template's extra sections (gate policy, lanes, design
skill = `impeccable`, notifications), reload, and dogfood one Lite ticket
before merging the branch. In-flight v1 tickets should finish on v1 first —
STATUS.md phase names differ (v2 adds QA phases, MERGED/CLOSED terminals).

## Improving the factory from project experience

The post-merge learning gate (protocol §8) captures *project* conventions into
the *project's* standards doc. When a lesson is about the **factory itself**
(a protocol gap, a better prompt), fix it in this repo, tag a release, note it
in the CHANGELOG, and roll it out with the update flow above — never fork
protocol.md inside one project, or portability dies the way v1's
code-reviewer drifted from CLAUDE.md.
