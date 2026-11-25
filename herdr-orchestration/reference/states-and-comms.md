# Herdr agent state + communication reference

Audience: an engineer building a dispatcher on top of herdr.
Method: every claim below is grounded in something run or read live on this box
(herdr 0.8.2, workspace w3, 2026-09-15) unless marked otherwise. Quoted command
output is real, trimmed for readability. Prior verified evidence from
`~/agent-lab/AGENTOS.md` (live herdr session notes, 2026-09-14) is cited
as such rather than re-proven.

---

## 1. The five states

`idle` · `working` · `blocked` · `done` · `unknown`

| State | Precise meaning |
|---|---|
| `working` | A turn is executing. Push channel reported it (opencode `chat.message` / tool events) or a `*_working` detection rule matched the terminal. |
| `idle` | The agent sits at an input prompt with no outstanding work. Either hook-reported (`session.idle`) or an `*_idle` rule matched (e.g. claude `live_prompt_box`, priority 950, region `prompt_box_body`). |
| `blocked` | herdr recognised an approval/question dialog. A headless `claude -p` that hits a prompt just hangs; a herdr-hosted one is legibly `blocked`. This is the state that makes unattended fleets safe. Route to a desktop notification, never auto-answer. |
| `done` | Idle **after unseen background work finished**. Focusing the tab (or targeting it with a focus command) marks it seen; CLI reads do **not**. Harvest the report on `done`. |
| `unknown` | An agent is there but unclassifiable (no integration, no matching rule). **It does not prove completion. Never harvest a result on `unknown`.** |

Seen-marking rule (AGENTOS.md, verified): only *focus* transitions `done`→seen.
`agent read` / `pane read` never mark seen, so polling output cannot accidentally
consume the completion signal your dispatcher waits on.

### Push vs pull per agent kind (verified)

| Kind | Session identity (always push) | State | Screen detection |
|---|---|---|---|
| claude (hook v8) | `SessionStart` hook → `pane.report_agent_session` | detection rules only (`claude.toml`) | active |
| hermes (plugin v5) | plugin → `herdr pane report-agent-session` CLI | detection rules only (`hermes.toml`) | active |
| opencode (plugin v10) | `session.updated` → `pane.report_agent_session` | **push, full lifecycle** (`pane.report_agent`) | **skipped** (`full_lifecycle_hook_authority`) |

Proof — opencode panes carry no rule verdict at all:

```
$ herdr agent explain w3:p3 --verbose
agent: opencode
state: working
manifest: none unknown
rule: none
screen_detection_skip_reason: full_lifecycle_hook_authority
visible: idle=false blocker=false working=false
```

```
$ herdr agent explain w5:p1 --verbose
agent: opencode
state: blocked
manifest: none unknown
rule: none
screen_detection_skip_reason: full_lifecycle_hook_authority
visible: idle=false blocker=false working=false
```

w5:p1 is `blocked` with `rule: none` — that verdict came 100% from the push
channel (opencode's `permission.asked`/`question.asked` → `reportState("blocked")`).
**When `manifest: none` + `rule: none`, the push channel is the sole authority;
there is no screen fallback.** Conversely, when a hook only reports identity
(claude, hermes), the TOML rules are the sole state authority.

A pane with no recognised agent has no verdict to explain at all:

```
$ herdr agent explain w3:pA --verbose   # w3:pA runs nvim, no agent
{"error":{"code":"agent_not_found","message":"agent target w3:pA not found"},"id":"cli:agent:explain"}
```

(Such panes surface as `agent_status: unknown` in pane listings — unclassifiable,
never "done".)

---

## 2. Channel A — push: hooks and plugins

Installed per agent kind by `herdr integration install <kind>`. Live status:

```
$ herdr integration status
pi: current (v8) (...)
claude: current (v8) (~/.claude/hooks/herdr-agent-state.sh)
codex: current (v8) (~/.codex/herdr-agent-state.sh)
copilot: current (v3) (~/.copilot/hooks/herdr-agent-state.sh)
opencode: current (v10) (~/.config/opencode/plugins/herdr-agent-state.js)
hermes: current (v5) (~/.hermes/plugins/herdr-agent-state/__init__.py)
cursor: not installed ...   grok: not installed ...   # → state reads unknown
... (gemini, qodercli, qwen, kilo, kimi, droid, devin, omp, mastracode, antigravity-cli: not installed)
```

The gate is environment: herdr injects coordinates into every managed pane
(verified in this shell):

```
HERDR_SOCKET_PATH=~/.config/herdr/herdr.sock
HERDR_ENV=1 HERDR_WORKSPACE_ID=w3 HERDR_PANE_ID=w3:p3
```

Every integration no-ops unless `HERDR_ENV=1` with socket path + pane id set.

### 2a. Claude hook: identity only, subagents fenced out

`~/.claude/hooks/herdr-agent-state.sh` (v8, 101 lines), wired in
`~/.claude/settings.json` as a `SessionStart` hook:

```json
"hooks": {"SessionStart":[{"matcher":"*","hooks":[{"type":"command","command":"bash '~/.claude/hooks/herdr-agent-state.sh' session","timeout":10}]}]}
```

Behaviour read from source:

- Only action `session` does anything; anything else exits 0.
- Reads hook JSON from stdin, sends **one** JSON-RPC message over the unix socket
  (`AF_UNIX`, 0.5 s timeout, fire-and-forget):
  `pane.report_agent_session` with `pane_id`, `source: "herdr:claude"`,
  `agent: "claude"`, `seq = time.time_ns()`, `agent_session_id` (+ transcript path
  and start source when present).
- **Subagent fence:** any event carrying `agent_id`, and `SubagentStop`
  specifically, exits without reporting — "Never let it revive an idle pane."
  Only the main turn moves pane state.
- It never sends `pane.report_agent` (no state). Claude state is purely Channel B.

### 2b. Opencode plugin: full-lifecycle state machine

`~/.config/opencode/plugins/herdr-agent-state.js` (v10, 197 lines). Key points:

- Sequence is a process-local monotonic counter seeded at `Date.now() * 1000`,
  `+1` per message — every `pane.report_agent` / `pane.report_agent_session`
  carries `seq: nextReportSeq()`. (Server-side stale-discard of lower-seq
  messages is the documented contract for the `(pane, source)` key; the monotonic
  fields above are verified in source, the discard itself is not observable via CLI.)
- Event → state map: `chat.message` / `tool.execute.before|after` /
  `permission.replied` / `question.replied|rejected` / `session.compacted` →
  `working`; `permission.asked` / `question.asked` / `session.error` → `blocked`;
  `session.idle` → `idle`. Session statuses map the same way
  (`idle→idle`, everything active-ish → `working`).
- **Child-session fence:** sessions with a `parentID` are recorded in
  `childSessions`; their prompts project state *without* attaching the child id,
  so the pane's root session is never replaced. (Same intent as Claude's
  subagent fence, different mechanism.)
- Requests are serialised through a promise chain, 500 ms socket timeout,
  all errors swallowed — a dead socket never breaks the agent.

### 2c. Hermes plugin: identity only, via CLI

`~/.hermes/plugins/herdr-agent-state/__init__.py` (v5, 77 lines,
"report resumable session identity"): instead of raw sockets it shells out to
`herdr pane report-agent-session <pane> --source herdr:hermes --agent hermes
--seq <time.time_ns()> --agent-session-id ...`, and only for interactive
platforms (`cli`/`tui`/`desktop`/`acp`). No state reporting — hermes state is
purely Channel B, like claude.

---

## 3. Channel B — pull: versioned detection rule-packs

Location: `~/.local/state/herdr/agent-detection/remote/<kind>.toml`
(`id`, `version`, `min_engine_version`, `aliases` header + `[[rules]]` list).
Rules are priority-ordered; each names a `state`, a `region` of structured
terminal content, and matchers (`contains` / `regex` / `line_regex` / `any` /
`all` / `not`). Regions seen in the wild: `osc_title`, `osc_progress`,
`prompt_box_body`, `bottom_non_empty_lines(N)`, `last_non_empty_above_prompt_box`,
`after_last_horizontal_rule`, `whole_recent`. Some rules carry `visible_working` /
`visible_idle` / `visible_blocker` flags (surfaced in explain output) and some are
`skip_state_update = true` (evaluated but never move state, e.g. transcript
viewer, model picker).

`claude.toml` (v2026.09.11.1, 15 rules) is a good study of the arms race:
`osc_title_working` (priority 1100, braille/half-circle spinner glyphs in the
OSC title) outranks `live_turn_working` (970, `esc to interrupt` / `…` activity
lines), which outranks the blocked family (`live_blocked_form`,
`mcp_elicitation_prompt` at 980 — the MCP comment cites a real missed-detection
issue #3283), with `live_prompt_box` idle at 950 and low-priority legacy
fallbacks (`legacy_no_prompt_blocker` at 300, `osc_title_idle` /
`osc_progress_idle` at 250).

`opencode.toml` (v2026.06.10.1, 3 rules) is vestigial *on this box* — the v10
plugin's hook authority supersedes it (see `manifest: none` above). It still
documents the shapes: `permission_required` blocked at 300
(`△ Permission required`, `esc dismiss` + `enter confirm`), `interrupt_hint_working`
at 110, `progress_bar_working` at 100 (runs of `■`/`⬝`).

`hermes.toml` (v2026.07.24.1) leads with OSC-title rules (`^⚠` blocked at 1100,
`^⏳` working at 1050) then content rules (`dangerous_command_approval`,
`clarification_prompt`, `credential_prompt`, `confirmation_prompt` at 900,
`interrupt_status_working` at 950).

### The tool that explains it: `herdr agent explain`

`herdr agent explain <pane-or-name> --verbose` prints the winning rule, its
priority and region, the evidence string, and every evaluated rule with ✓/✗.
Run it against several live panes — real output:

Claude, working, won on the OSC title (priority 1100 beats everything):

```
$ herdr agent explain w3:p1 --verbose
agent: claude
state: working
manifest: remote:~/.local/state/herdr/agent-detection/remote/claude.toml 2026.09.11.1
rule: osc_title_working (region=osc_title priority=1100)
evidence: "◑ Herdr multi-agent orchestration and AgentOS"
visible: idle=false blocker=false working=true
...
evaluated_rules:
  ✓ osc_title_working priority=1100 region=osc_title state=working
  ✓ live_turn_working priority=970 region=bottom_non_empty_lines(12) state=working
  ...
  ✓ live_prompt_box priority=950 region=prompt_box_body state=idle
  ...
```

Note two rules matched simultaneously (`osc_title_working` *and*
`live_prompt_box` idle) — **highest priority wins**, no voting. The `✗` lines
show near-misses with byte counts and previews, which is how you debug a
mis-detected pane.

Hermes, working, won on content (status bar shows the pinned model, incidentally
confirming a cross-pane model switch landed):

```
$ herdr agent explain w3:p7 --verbose
agent: hermes
state: working
manifest: remote:~/.local/state/herdr/agent-detection/remote/hermes.toml 2026.07.24.1
rule: interrupt_status_working (region=bottom_non_empty_lines(5) priority=950)
evidence: "  💻 sleep 90 + 3 commands  ( 27.8s · ↓ 4.3k tok)\n\n ☤ deepseek-v4.1-flash │ ~124K/1M │ ..."
visible: idle=false blocker=false working=true
```

### When pull and push disagree

During this investigation `herdr agent list` showed `w4:p1 claude blocked`
while `herdr agent explain w4:p1 --verbose` evaluated to
`state: working ... rule: osc_title_working ... evidence: "◑ affine-agent-research-plan"`.
Two readings, both honest: the fused/latched state said `blocked` (a blocker
was recognised — e.g. a permission dialog seen earlier), while the *current*
screen re-evaluated to `working` (spinner running). Dispatcher rule of thumb:
treat `blocked` as sticky and authoritative for safety (it exists to make
approval dialogs legible), and use `explain` to see *why the screen disagrees*
before deciding the blockage cleared. Never infer completion from the
disagreement resolving — only `done` (or `idle` you caused) means done.

---

## 4. Communication, four levels

### Level 1 — discovery: `agent list` / `agent get`

```
$ herdr agent list
w3:p1 claude   working   Herdr multi-agent orchestration and AgentOS
w3:p7 hermes   working   user@host:~/agent-lab
w3:p2 hermes   working   user@host:~/agent-lab
w3:p3 opencode working   OpenCode
w3:pC claude   working   ...
w4:p1 claude   blocked   affine-agent-research-plan
w4:p2 opencode working   OpenCode
w5:p1 opencode blocked   OpenCode
```

`agent get <pane>` returns the full record: kind, fused `agent_status`,
`agent_session` triple (`agent`/`kind`/`source`/`value` — the push-channel
identity), `screen_detection_skipped`, `state_change_seq`, `revision`,
terminal title, cwd/tab/workspace, plus `tokens` (see §7). Name agents after
their work item (`aos-2`, not `reviewer`) and this list becomes a live view of
which items are executing.

### Level 2 — reading: `agent read` and the alternate-screen ceiling

Sources: `visible` (viewport), `recent` / `recent-unwrapped` (host scrollback),
`detection` (what the rules see). Two verified limits (AGENTOS.md §3, live
session evidence):

- `recent`/`recent-unwrapped` can be **empty (0 bytes)** on a fresh pane whose
  output never scrolled — they read host scrollback, and there isn't any yet.
  Short-lived panes: read `visible`. Long logs: `recent-unwrapped`.
- **Alternate-screen TUIs are unrecoverable past the viewport.** Agent TUIs run
  on the alt screen; rows that leave it never enter scrollback, so a bigger
  `--lines` cannot recover them. Fallback *after* a failed read (not in the
  first prompt): ask the agent to write its full report to a temp `.md` and reply
  with only the path, then read the file.

### Level 3 — sending: `agent prompt`, `send-keys`, and refusal

`herdr agent prompt <TARGET> <TEXT> [--wait] [--until <state>] [--timeout <MS>]`
submits text to a live agent. Semantics verified from CLI help + live use:

- If the agent is already `blocked`, submission is **rejected with
  `agent_blocked` before any input is sent** — prompts never pile up behind an
  approval dialog.
- With `--wait`, herdr first requires an observed state change within 5000 ms
  (`agent_prompt_stalled` otherwise), then matches `idle`/`done`/`blocked` by
  default. It does not track turns: if the agent was already `working`, that
  active turn's completion may match.
- `herdr agent start <name> --kind <kind> --pane <pane>` needs an **existing
  pane already at an interactive prompt** — it never creates layout. Split first,
  always; pass `--no-focus` on everything unattended or you yank the human's
  cursor mid-typing.

Live proof from this box: a prompt dispatched to the hermes pane from a sibling
pane was accepted and acted on without touching focus:

```
$ herdr agent prompt w3:p2 "Read ~/agent-lab/idea-queue-research-brief.md and execute it ..."
{"id":"cli:agent:prompt","result":{"agent":{"agent":"hermes",...,"pane_id":"w3:p2",...},"type":"agent_prompted"}}
```

Twenty-five seconds later `herdr agent get w3:p2` showed the transition
`idle → working`, and `agent read` showed the brief being executed
(`read idea-queue-research-brief.md`, model-switch commands). `send-keys`
targets the same way (`herdr agent send-keys <TARGET> <KEY>...`, `esc` canonical)
for raw keypresses. Never close what you did not create, and never
`herdr server stop` from a live session.

### Level 4 — blackboard: metadata tokens

Structured, queryable, session-scoped key/value state without typing into any
terminal: `herdr pane report-metadata` and `herdr workspace report-metadata`
with `--token k=v`, `--seq`, `--ttl-ms`, `--clear-token`. Tokens surface on
`agent get` (pane) and `workspace list` (workspace). Tested live on my own pane
(note: the positional pane/workspace id comes **first** — `--source` before it
fails with `unknown option`):

```
$ herdr pane report-metadata w3:p3 --source doc-probe --token probe_key=probe_value_42
(no output = success)
$ herdr agent get w3:p3
  ...
  "revision": 3,          # was 2 — metadata write bumps revision, not state_change_seq (142, unchanged)
  "tokens": {
    "probe_key": "probe_value_42"
  },
```

```
$ herdr workspace report-metadata w3 --source doc-probe --token ws_probe=ws_value_7 --ttl-ms 120000
$ herdr workspace list
  {"workspace_id":"w3", ..., "tokens": {"ws_probe": "ws_value_7"}, ...}
```

Cleanup, verified:

```
$ herdr pane report-metadata w3:p3 --source doc-probe --clear-token probe_key
$ herdr workspace report-metadata w3 --source doc-probe --clear-token ws_probe
$ herdr agent get w3:p3   →  pane tokens: None
$ herdr workspace list    →  ws tokens: None
```

Limits, as observed: tokens are **session-scoped and in-memory** (die with the
server), **TTL'd** only if you pass `--ttl-ms`, have **no ACLs** (any pane can
write any token under any `--source` string — treat `source` as a label, not
auth), and metadata writes bump `revision` without touching `state_change_seq`
— so token traffic never corrupts the state-change ordering your dispatcher
relies on.

---

## 5. Dispatcher cheat-sheet

1. Claim in Kaneo (move the task to `in-progress` + `CLAIMED` comment); name the herdr agent after the task key (`DUET-2` → `duet-2`).
2. `pane split --no-focus` → `agent start <item> --kind <k> --pane <p>`.
3. `agent prompt <item> <brief> --wait --timeout <ms>`; match `idle`/`done`/`blocked`.
4. `blocked` → notify human, never auto-answer. `unknown` → never "done".
5. Harvest via `agent read visible`; if the TUI scrolled, have the agent dump to a file.
6. Report back to Kaneo as a task comment (SUMMARY / CHANGES / TESTS / FOLLOWUPS); close only panes you created.
7. Coordinate across panes with metadata tokens, not typed messages; always `--clear-token`.
8. When a state looks wrong, `herdr agent explain <pane> --verbose` shows the exact winning rule and evidence — paste it into the bug report.
