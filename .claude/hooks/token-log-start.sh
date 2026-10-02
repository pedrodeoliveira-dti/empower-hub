#!/usr/bin/env bash
# UserPromptSubmit hook: records when a command/prompt started so token-log-stop.sh
# can compute duration and token usage once Claude finishes responding.
set -euo pipefail

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
prompt=$(echo "$input" | jq -r '.prompt // ""' | tr '\n' ' ' | cut -c1-200)
start_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state_dir="$project_dir/.claude/.token-usage-state"
mkdir -p "$state_dir"

state_file="$state_dir/$session_id.json"

# A state file can already exist here if the harness fires UserPromptSubmit more
# than once before the matching Stop (e.g. synthetic <ide_opened_file> events
# alongside the real prompt). Keep the EARLIEST start_time/start_line so token
# accounting still covers the whole in-flight turn, and append the new prompt
# text rather than clobbering the original one.
if [ -f "$state_file" ]; then
  start_time=$(jq -r '.start_time' "$state_file")
  start_line=$(jq -r '.start_line' "$state_file")
  prev_command=$(jq -r '.command' "$state_file")
  prompt="${prev_command} | ${prompt}"
else
  start_line=0
  if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    start_line=$(wc -l < "$transcript_path" | tr -d ' ')
  fi
fi

jq -n \
  --arg start_time "$start_time" \
  --arg command "$prompt" \
  --arg transcript_path "$transcript_path" \
  --argjson start_line "$start_line" \
  '{start_time: $start_time, command: $command, transcript_path: $transcript_path, start_line: $start_line}' \
  > "$state_file"
