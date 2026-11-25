# herdr-orchestration skill

An agent skill for driving [herdr](https://github.com/herdrdev/herdr) — the terminal multiplexer for coding agents — to place panes, start named agents, prompt and wait on them, read their output, and share state between them.

Battle-tested against **herdr 0.8.2** on a live multi-agent box (Claude Code, Codex, OpenCode, Hermes). The gotchas section covers things that are not in `herdr --skill`.

## Contents

| Path | What |
|---|---|
| `herdr-orchestration/SKILL.md` | The skill (Claude Code / Agent Skills format) |
| `herdr-orchestration/reference/commands.md` | Full CLI help, generated from the binary |
| `herdr-orchestration/reference/states-and-comms.md` | Deep reference: lifecycle states, push hooks vs pull detection rules, `agent explain`, 4 levels of inter-agent comms |
| `herdr-orchestration/bin/gen-herdr-command-index.sh` | Regenerates `commands.md` from your installed herdr |
| `AGENTS.md` | Everything above flattened for non-skill harnesses (Codex, OpenCode, etc.), with a one-line-per-command CLI index |
| `build.sh` | Regenerates `commands.md` and `AGENTS.md` |

## Install

**Claude Code (user-level):**
```bash
git clone https://github.com/kyl-er/herdr-orchestration-skill
cp -r herdr-orchestration-skill/herdr-orchestration ~/.claude/skills/
```

**Other harnesses:** drop `AGENTS.md` into your project root (or reference it from your existing `AGENTS.md`).

**Hermes / other skill dirs:** copy `herdr-orchestration/` into that harness's skills folder.

## Keep it current

```bash
./build.sh   # re-dumps the CLI from your installed herdr and rebuilds AGENTS.md
```

## Notes

- `reference/states-and-comms.md` quotes real output from the author's machine (pane ids like `w3:p1`); treat those as examples.
- The skill mentions Kaneo as the durable task store for dispatch — swap in whatever tracker you use.

MIT licensed.
