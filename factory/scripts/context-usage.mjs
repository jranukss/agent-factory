#!/usr/bin/env node
// Reports the current Claude Code session's REAL context-window usage by
// reading the newest session transcript for this project
// (~/.claude/projects/<project-slug>/<session-id>.jsonl): the last main-chain
// assistant entry's usage block is the context occupancy at the last API call.
//
// Usage:   node .claude/factory/scripts/context-usage.mjs [transcript.jsonl]
// Output:  one JSON line: {"tokens":159206,"window":200000,"pct":79.6,...}
// Exit 1 + stderr message when usage cannot be determined — callers fall back
// to judgment (factory protocol §10) and never block on measurement.
//
// Caveats: the transcript format is undocumented and may change; with two
// simultaneous sessions in the same project, "newest transcript" may pick the
// other one (pass the transcript path explicitly to disambiguate).

import { readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

function newestTranscript() {
  const slug = process.cwd().replace(/[^a-zA-Z0-9]/g, "-");
  const dir = join(homedir(), ".claude", "projects", slug);
  const files = readdirSync(dir).filter((f) => f.endsWith(".jsonl"));
  if (files.length === 0) throw new Error("no transcripts in " + dir);
  return files
    .map((f) => join(dir, f))
    .sort((a, b) => statSync(b).mtimeMs - statSync(a).mtimeMs)[0];
}

try {
  const file = process.argv[2] ?? newestTranscript();
  const lines = readFileSync(file, "utf8").trim().split("\n");
  let found = false;
  for (let i = lines.length - 1; i >= 0 && !found; i--) {
    let entry;
    try {
      entry = JSON.parse(lines[i]);
    } catch {
      continue;
    }
    // Sidechain entries are subagent turns — their usage reflects the
    // subagent's context, not the orchestrator session's.
    if (entry.type !== "assistant" || entry.isSidechain) continue;
    const usage = entry.message?.usage;
    if (!usage || usage.input_tokens === undefined) continue;
    const tokens =
      (usage.input_tokens || 0) +
      (usage.cache_read_input_tokens || 0) +
      (usage.cache_creation_input_tokens || 0);
    const model = entry.message.model ?? "unknown";
    const window = /\[1m\]/.test(model) ? 1_000_000 : 200_000;
    console.log(
      JSON.stringify({
        tokens,
        window,
        pct: Math.round((tokens / window) * 1000) / 10,
        model,
        transcript: file,
      }),
    );
    found = true;
  }
  if (!found) throw new Error("no assistant usage entries found");
} catch (err) {
  console.error("context-usage: " + (err?.message ?? err));
  process.exit(1);
}
