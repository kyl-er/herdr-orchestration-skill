# herdr command index

Generated from `herdr --help` and each command group by
`bin/gen-herdr-command-index.sh`. Do not hand-edit - re-run it instead.

- version: `herdr 0.8.2`
- generated: 2026-11-25T10:37:52-08:00

Discovery rule: the installed binary is the authority. Run a group with no
subcommand to print its syntax. Never run bare `herdr` to explore - it
launches or attaches the TUI. Never probe a mutating nested command by
omitting arguments; `herdr workspace create` is valid with defaults and will run.

```
Usage: herdr [options]
       herdr --session <name> [options]
       herdr --remote <ssh-target> [--session <name>]
       herdr session attach <name>
       herdr completion zsh
       herdr update [--handoff]
       herdr channel set <stable|preview>
       herdr server stop
       herdr server reload-config
       herdr api <subcommand> ...
       herdr completion <shell>
       herdr config <subcommand> ...
       herdr channel <subcommand> ...
       herdr workspace <subcommand> ...
       herdr worktree <subcommand> ...
       herdr tab <subcommand> ...
       herdr notification <subcommand> ...
       herdr agent <subcommand> ...
       herdr pane <subcommand> ...
       herdr session <subcommand> ...
       herdr integration <subcommand> ...

Common commands:
  herdr                            Launch or attach to the persistent session
  herdr status [server|client]     Show local client and running server status
  herdr update                     Download and install the latest version
  herdr completion zsh             Generate shell completions for zsh
  herdr server stop                Stop the running server via the API socket
  herdr channel set <stable|preview> Choose the stable or preview update channel
  herdr server reload-config       Reload config.toml in the running server
  herdr config reset-keys          Back up config.toml and remove custom keybindings
  herdr channel <subcommand>       Manage the stable or preview update channel
  herdr api <subcommand>           Inspect socket API metadata and live runtime state
  herdr workspace <subcommand>     Workspace helpers over the socket API
  herdr worktree <subcommand>      Git worktree helpers over the socket API
  herdr tab <subcommand>           Tab helpers over the socket API
  herdr notification <subcommand>  Notification helpers over the socket API
  herdr agent <subcommand>         Agent/terminal helpers over the socket API
  herdr pane <subcommand>          Pane control helpers over the socket API
  herdr session <subcommand>       Manage named persistent sessions
  herdr integration <subcommand>   Manage built-in agent integrations

Advanced commands:
  herdr server                     Run as headless server

Options:
```

## herdr api

```
herdr api commands:
  herdr api snapshot
  herdr api schema [--json | --output PATH]
```

## herdr config

```
herdr config commands:
  herdr config check  validate config.toml and print diagnostics
  herdr config reset-keys  back up config.toml and remove custom keybindings
```

## herdr channel

```
herdr channel commands:
  herdr channel show                  print the configured update channel
  herdr channel set <stable|preview>  choose the update channel
```

## herdr workspace

```
herdr workspace commands:
  herdr workspace list
  herdr workspace create [--cwd PATH] [--label TEXT] [--env KEY=VALUE] [--focus] [--no-focus]
  herdr workspace get <workspace_id>
  herdr workspace focus <workspace_id>
  herdr workspace rename <workspace_id> <label>
  herdr workspace report-metadata <workspace_id> --source ID [--token NAME=VALUE] [--clear-token NAME] [--seq N] [--ttl-ms N]
  herdr workspace close <workspace_id>
```

## herdr worktree

```
herdr worktree commands:
  herdr worktree list [--workspace ID | --cwd PATH]
  herdr worktree create [--workspace ID | --cwd PATH] [--branch NAME] [--base REF] [--path PATH] [--label TEXT] [--focus] [--no-focus]
  herdr worktree open [--workspace ID | --cwd PATH] (--path PATH | --branch NAME) [--label TEXT] [--focus] [--no-focus]
  herdr worktree remove --workspace ID [--force]
```

## herdr tab

```
herdr tab commands:
  herdr tab list [--workspace <workspace_id>]
  herdr tab create [--workspace <workspace_id>] [--cwd PATH] [--label TEXT] [--env KEY=VALUE] [--focus] [--no-focus]
  herdr tab get <tab_id>
  herdr tab focus <tab_id>
  herdr tab rename <tab_id> <label>
  herdr tab close <tab_id>
```

## herdr notification

```
herdr notification commands:
  herdr notification show <title> [--body TEXT] [--position top-left|top-right|bottom-left|bottom-right] [--sound none|done|request]
```

## herdr agent

```
herdr agent commands:
  herdr agent list
  herdr agent get <target>
  herdr agent read <target> [--source visible|recent|recent-unwrapped|detection] [--lines N] [--format text|ansi] [--ansi]
  herdr agent send-keys <target> <key> [key ...]
  herdr agent prompt <target> <text> [--wait] [--until STATUS]... [--timeout MS]
  herdr agent rename <target> <name>|--clear
  herdr agent focus <target>
  herdr agent wait <target> [--until STATUS]... [--timeout MS]
  herdr agent attach <target> [--takeover]
  herdr agent start <name> --kind KIND --pane ID [--timeout MS] [-- <agent-args...>]
  herdr agent explain <target> [--json|--format text|json] [--verbose]
  herdr agent explain --file PATH --agent LABEL [--json|--format text|json] [--verbose]
  targets accept unique agent names and pane ids that currently host agents
  kinds: pi|claude|codex|gemini|cursor|devin|agy|cline|omp|mastracode|opencode|copilot|kimi|kiro|droid|amp|grok|hermes|kilo|qodercli|qwen|maki
```

## herdr pane

```
herdr pane commands:
  herdr pane list [--workspace <workspace_id>]
  herdr pane current [--pane ID|--current]
  herdr pane get <pane_id>
  herdr pane layout [--pane ID|--current]
  herdr pane process-info [--pane ID|--current]
  herdr pane neighbor --direction left|right|up|down [--pane ID|--current]
  herdr pane edges [--pane ID|--current]
  herdr pane focus --direction left|right|up|down [--pane ID|--current]
  herdr pane resize --direction left|right|up|down [--amount FLOAT] [--pane ID|--current]
  herdr pane zoom [<pane_id>|--pane ID|--current] [--toggle|--on|--off]
  herdr pane rename <pane_id> <label>|--clear
  herdr pane read <pane_id> [--source visible|recent|recent-unwrapped] [--lines N] [--format text|ansi] [--ansi]
  herdr pane input [<pane_id>|--pane ID|--current] --right-click herdr|pane
  herdr pane split [<pane_id>|--pane ID|--current] --direction right|down [--ratio FLOAT] [--cwd PATH] [--env KEY=VALUE] [--right-click herdr|pane] [--focus] [--no-focus]
  herdr pane swap --direction left|right|up|down [--pane ID|--current]
  herdr pane swap --source-pane ID --target-pane ID
  herdr pane move <pane_id> --tab <tab_id> --split right|down [--target-pane ID] [--ratio FLOAT] [--focus|--no-focus]
  herdr pane move <pane_id> --new-tab [--workspace ID] [--label TEXT] [--focus|--no-focus]
  herdr pane move <pane_id> --new-workspace [--label TEXT] [--tab-label TEXT] [--focus|--no-focus]
  herdr pane close <pane_id>
  herdr pane send-text <pane_id> <text>
  herdr pane send-keys <pane_id> <key> [key ...]
  herdr pane wait-output <pane_id> (--match TEXT | --regex PATTERN) [--source visible|recent|recent-unwrapped] [--lines N] [--timeout MS] [--raw]
  herdr pane report-agent <pane_id> --source ID --agent LABEL --state idle|working|blocked|unknown [--message TEXT] [--seq N] [--agent-session-id ID] [--agent-session-path PATH]
  herdr pane report-agent-session <pane_id> --source ID --agent LABEL [--seq N] [--agent-session-id ID] [--agent-session-path PATH]
  herdr pane release-agent <pane_id> --source ID --agent LABEL [--seq N]
  herdr pane report-metadata <pane_id> --source ID [--agent LABEL] [--applies-to-source ID] [--title TEXT|--clear-title] [--display-agent TEXT|--clear-display-agent] [--state-label STATUS=TEXT] [--clear-state-labels] [--token NAME=VALUE] [--clear-token NAME] [--seq N] [--ttl-ms N]
  herdr pane run <pane_id> <command>
```

## herdr session

```
herdr session commands:
  herdr session list [--json]
  herdr session attach <name>
  herdr session stop <name> [--json]
  herdr session delete <name> [--json]
  use 'default' as <name> to target the default session for stop
```

## herdr integration

```
herdr integration commands:
  herdr integration install pi
  herdr integration install omp
  herdr integration install claude
  herdr integration install codex
  herdr integration install copilot
  herdr integration install devin
  herdr integration install droid
  herdr integration install kimi
  herdr integration install opencode
  herdr integration install kilo
  herdr integration install hermes
  herdr integration install qodercli
  herdr integration install qwen
  herdr integration install cursor
  herdr integration install mastracode
  herdr integration install antigravity-cli
  herdr integration install grok
  herdr integration uninstall pi
  herdr integration uninstall omp
  herdr integration uninstall claude
  herdr integration uninstall codex
  herdr integration uninstall copilot
  herdr integration uninstall devin
  herdr integration uninstall droid
  herdr integration uninstall kimi
  herdr integration uninstall opencode
  herdr integration uninstall kilo
  herdr integration uninstall hermes
  herdr integration uninstall qodercli
  herdr integration uninstall qwen
  herdr integration uninstall cursor
  herdr integration uninstall mastracode
  herdr integration uninstall antigravity-cli
  herdr integration uninstall grok
  herdr integration status [--outdated-only]
```
