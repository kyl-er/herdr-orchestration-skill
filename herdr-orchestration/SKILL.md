---
name: herdr-orchestration
description: >
  Drive herdr to run and coordinate multiple coding agents (from inside or outside a
  herdr pane): place panes, start named agents, prompt and wait on them, read their output, and
  share state between them. Use when the task involves herdr, delegating work to
  another agent, running agents in parallel, checking what other agents are doing,
  or any `herdr` CLI command. Triggers: herdr, pane, workspace/tab/pane topology,
  agent list/start/prompt/read/send-keys/wait, multi-agent, delegate, fleet,
  agent state (idle/working/blocked/done/unknown), metadata tokens, worktree
  isolation. Do NOT use merely because a task could benefit
  from a background terminal.
---

# herdr orchestration

herdr is a terminal multiplexer for coding agents. It owns the workspace/tab/pane tree,
recognises which agent occupies each pane and what lifecycle state it is in, and exposes
all of it over a socket API as JSON.

**The CLI works from anywhere.** herdr talks to its server over a socket, so `herdr agent
list`, `herdr workspace list`, `herdr agent read` etc. work from a plain terminal or a
non-herdr session too. Only the `$HERDR_*` variables below depend on running inside a pane;
outside one, use `--pane <id>` / explicit targets instead of `--current` and `$HERDR_PANE_ID`.

Inside a herdr pane, your own coordinates are injected: `$HERDR_WORKSPACE_ID` `$HERDR_TAB_ID` `$HERDR_PANE_ID`.

## Command index

`reference/commands.md` — generated from the installed binary by
`bin/gen-herdr-command-index.sh`. **The binary is the authority**, not this file: run a
group with no subcommand (`herdr agent`, `herdr pane`) to print current syntax. Never run
bare `herdr` to explore — it launches the TUI. Never probe a mutating nested command by
omitting arguments; `herdr workspace create` is valid with defaults and will execute.

## The delegation loop

```bash
# 1. place a pane. Wide pane -> right, narrow/tall -> down.
#    Check first: herdr pane layout --pane "$HERDR_PANE_ID"
herdr pane split --current --direction right --cwd "$PWD" --no-focus
#    -> read .result.pane.pane_id from the JSON

# 2. start a named agent in that existing pane
herdr agent start aos-2 --kind codex --pane <pane-id>

# 3. submit work
herdr agent prompt aos-2 "<task>" --wait --timeout 900000

# 4. harvest
herdr agent read aos-2 --source visible --lines 120

# 5. clean up only what you created
herdr pane close <pane-id>
```

**Name the agent after the work item** it is executing (`AOS-2` → `aos-2`; names must match
`[a-z][a-z0-9_-]{0,31}`). Then `herdr agent list` is a live view of which items are running,
and every pane traces back to the item that authorised it.

`agent start` requires an **existing pane already at an interactive shell prompt**. It never
creates, splits or moves layout. Split first, always.

## Lifecycle states

`idle` · `working` · `blocked` · `done` · `unknown`

- `blocked` — herdr recognised an approval/question dialog. This is what makes unattended
  fleets safe. **Inspect it and ask the human before answering** — do not click through
  another agent's permission prompt on your own judgement.
- `done` — idle after *unseen* background work finished. Focusing the tab marks it seen;
  CLI reads do not.
- `unknown` — an agent is present but unclassifiable. **It never proves completion.**
  Neither does `idle` on an agent with no state-reporting hook installed (check
  `herdr integration status`); that idle can be a default fallback, not a detection.

Diagnose any state with `herdr agent explain <target> --verbose` — it prints the winning
rule, its priority and region, and the evidence string. Full mechanism in
`reference/states-and-comms.md`.

## Hard-won gotchas

These cost real time. They are not in `herdr --skill`.

**`--wait` tracks lifecycle state, not a turn.** It returns `done` the moment the agent
settles between steps, while it is still working. **Files on disk are the only trustworthy
completion signal** for a task that produces artifacts. Verify the deliverable, not the state.

**`pane wait-output` matches the echoed command itself.** It searches the snapshot
immediately and your command text is in it. Match a sentinel that cannot appear in the
command, or you match instantly and wait for nothing.

**`recent` / `recent-unwrapped` return 0 bytes on a fresh pane.** They read *host
scrollback*; if nothing has scrolled off yet there is nothing there. Use `visible` for
short-lived panes, `recent-unwrapped` for long logs.

**Use `--format ansi` when styling is evidence.** Plain-text reads strip highlighting, so a
selected dialog button is invisible. Confirming a dialog blind risks pressing Reject.
Check which option carries the highlight background *before* sending `enter`.

**Alt-screen TUIs lose rows past the viewport permanently.** A bigger `--lines` cannot
recover them. Fallback *after* a failed read (never in the first prompt): have the agent
write its full report to a file and reply with only the path.

**`--no-focus` on everything unattended**, or you yank the human's cursor mid-typing.

**Never close panes you did not create.** Never `herdr server stop` from a live session —
it kills every pane process including yours.

## Coordinating between agents

Four levels, cheapest first:

| level | command | use |
|---|---|---|
| discovery | `herdr agent list` | who exists, kind, state, cwd, tokens |
| reading | `herdr agent read <t>` | what another agent's screen shows |
| sending | `herdr agent prompt <t>` | give another agent work; refuses a `blocked` target |
| blackboard | `herdr pane report-metadata --token k=v` | structured shared state |

Prefer the blackboard over screen-scraping. Tokens surface in `herdr agent list`, so one
call returns every agent's identity, state **and** self-declared context:

```bash
herdr pane report-metadata "$HERDR_PANE_ID" --source dispatch --token item=AOS-2 \
  --token phase=implementing --ttl-ms 1800000
herdr workspace report-metadata "$HERDR_WORKSPACE_ID" --source dispatch --token budget=RUN
```

Tokens are session-scoped, in-memory, TTL'd and have no ACLs — a cooperative blackboard,
not a secured bus. Durable truth belongs in Kaneo (kaneo-orchestration skill). Clean up with `--clear-token`.

## Isolation

Give any high-risk or parallel-write task its own tree:

```bash
herdr worktree create --branch agent/aos-2 --base main
```

Two agents sharing one dirty working tree will corrupt each other's work.
