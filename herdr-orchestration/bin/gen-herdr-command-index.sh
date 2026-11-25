#!/usr/bin/env bash
# Regenerate the herdr command index from the installed binary's own help.
# The binary is the authority on syntax - never hand-edit the output.
set -euo pipefail
OUT="${1:-$(cd "$(dirname "$0")/.." && pwd)/reference/commands.md}"
HERDR_GROUPS=(api config channel workspace worktree tab notification agent pane session integration)

{
  echo "# herdr command index"
  echo
  echo "Generated from \`herdr --help\` and each command group by"
  echo "\`bin/gen-herdr-command-index.sh\`. Do not hand-edit - re-run it instead."
  echo
  echo "- version: \`$(herdr --version 2>&1)\`"
  echo "- generated: $(date -Iseconds)"
  echo
  echo "Discovery rule: the installed binary is the authority. Run a group with no"
  echo "subcommand to print its syntax. Never run bare \`herdr\` to explore - it"
  echo "launches or attaches the TUI. Never probe a mutating nested command by"
  echo "omitting arguments; \`herdr workspace create\` is valid with defaults and will run."
  echo
  echo '```'
  herdr --help 2>&1 | sed -n '/^Usage:/,/^Options:/p'
  echo '```'
  for g in "${HERDR_GROUPS[@]}"; do
    echo
    echo "## herdr $g"
    echo
    echo '```'
    herdr "$g" 2>&1 || true
    echo '```'
  done
} > "$OUT"
echo "wrote $OUT ($(wc -l < "$OUT") lines)"
