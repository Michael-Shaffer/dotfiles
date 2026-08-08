#!/usr/bin/env bash
# agent-job.sh — run one headless opencode job. For cron / dispatch / tmux.
#
# Usage: bin/agent-job.sh "<prompt>" [--dir /path/to/project] [--model <id>]
#
# Examples:
#   bin/agent-job.sh "run the test suite and report failures" --dir ~/myproject
#   bin/agent-job.sh "bump the changelog from this week's commits" --dir ~/myproject
#
# Exit code: 0 on success, non-zero on error. Wrap in cron TMUX, e.g.:
#   0 9 * * * /home/you/workflow/bin/agent-job.sh "morning status" --dir ~/project >> ~/agent-cron.log 2>&1

set -euo pipefail

DIR="$(pwd)"
MODEL=""
PROMPT="${1:-}"

if [ -z "$PROMPT" ]; then
  echo "usage: $0 \"<prompt>\" [--dir DIR] [--model id]" >&2
  exit 1
fi
shift

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir)   DIR="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    *) echo "unknown: $1" >&2; exit 1 ;;
  esac
done

[ -d "$DIR" ] || { echo "! no such dir: $DIR" >&2; exit 1; }
command -v opencode >/dev/null || { echo "! opencode not installed" >&2; exit 1; }

echo "==> $(date -Iseconds) job cwd=$DIR model=$MODEL"
args=(run "$PROMPT")
[ -n "$MODEL" ] && args+=(--model "$MODEL")

cd "$DIR"
opencode "${args[@]}"
rc=$?
echo "==> $(date -Iseconds) done rc=$rc"
exit "$rc"