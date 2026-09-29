#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|MultiEdit) — mechanically enforces this hub's
# "one product repo per session" rule (constitution/EMPOWER-HUB-CONSTITUTION.md
# Section 4; .claude/commands/speckit.implement.md) instead of relying only on
# prompt instructions.
#
# State is keyed by session_id under .claude/.hook-state/ so two Claude Code
# sessions running in parallel against this same hub checkout (e.g. one on
# MyIsn.Android, one on MyIsn.iOS, both working off the same approved
# tasks.md) never see each other's lock — each session gets its own.
#
# A hub-level file (docs/, specs/, .claude/, etc.) is never gated — this only
# fires once a write targets something inside MyIsn.Android/ or MyIsn.iOS/.
set -euo pipefail

input="$(cat)"
session_id="$(jq -r '.session_id // "unknown"' <<<"$input")"
file_path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"

if [ -z "$file_path" ]; then
  exit 0
fi

repo=""
case "$file_path" in
  */MyIsn.Android/*) repo="MyIsn.Android" ;;
  */MyIsn.iOS/*) repo="MyIsn.iOS" ;;
  *) exit 0 ;;
esac

state_dir=".claude/.hook-state"
mkdir -p "$state_dir"
lock_file="$state_dir/${session_id}.repo-lock"
switch_file="$state_dir/${session_id}.repo-switch-ok"

if [ ! -f "$lock_file" ]; then
  echo "$repo" > "$lock_file"
  exit 0
fi

locked_repo="$(cat "$lock_file")"

if [ "$locked_repo" = "$repo" ]; then
  exit 0
fi

# Repo switch requested — allow once if the one-time override marker is present.
if [ -f "$switch_file" ]; then
  rm -f "$switch_file"
  echo "$repo" > "$lock_file"
  exit 0
fi

reason="Hub rule (constitution/EMPOWER-HUB-CONSTITUTION.md Section 4, .claude/commands/speckit.implement.md): one product repo per session. This session already wrote inside ${locked_repo}; blocking this write inside ${repo}. If the user has explicitly confirmed switching repos for this task, run this exact command, then retry the edit: mkdir -p ${state_dir} && touch ${switch_file}"

jq -n --arg reason "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
