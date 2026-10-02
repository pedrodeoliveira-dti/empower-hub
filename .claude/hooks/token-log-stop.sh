#!/usr/bin/env bash
# Stop hook: closes out the record opened by token-log-start.sh, summing token
# usage reported in the transcript since the command started, and appends one
# row to this user's own CSV file under .claude/token-usage/.
#
# One file per repo user (keyed off `git config user.email`, falling back to
# user.name / $USER) so concurrent contributors never touch the same file —
# each person only ever appends to their own CSV, so there is nothing to
# merge-conflict on. The CSVs are local (gitignored); open them in any
# spreadsheet to analyze usage.
#
# NOTE on "daily limit": Claude Code hooks do not expose Anthropic's actual
# account-level rate-limit status, so this is a locally-tracked token budget,
# not the real API rate limit. Configure it via the CLAUDE_TOKEN_DAILY_LIMIT
# env var (see .claude/settings.json); defaults to 1,000,000 tokens/day.
set -euo pipefail

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
end_time=$(date -u +%Y-%m-%dT%H:%M:%SZ)

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state_dir="$project_dir/.claude/.token-usage-state"
state_file="$state_dir/$session_id.json"
daily_limit_tokens="${CLAUDE_TOKEN_DAILY_LIMIT:-1000000}"

user=$(git -C "$project_dir" config --get user.email 2>/dev/null || true)
[ -z "$user" ] && user=$(git -C "$project_dir" config --get user.name 2>/dev/null || true)
[ -z "$user" ] && user="${USER:-unknown}"
user_slug=$(echo "$user" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/_/g')
[ -z "$user_slug" ] && user_slug="unknown"

csv_dir="$project_dir/.claude/token-usage"
mkdir -p "$csv_dir"
csv_file="$csv_dir/$user_slug.csv"

new_header="start_time,end_time,duration_seconds,session_id,user,command,model,effort_level,category,category_detail,input_tokens,output_tokens,cache_creation_tokens,cache_read_tokens,total_tokens,daily_tokens_so_far,daily_limit_tokens,daily_limit_reached"

if [ ! -f "$csv_file" ]; then
  echo "$new_header" > "$csv_file"
fi

start_time=""
command=""
start_line=0
if [ -f "$state_file" ]; then
  start_time=$(jq -r '.start_time // ""' "$state_file")
  command=$(jq -r '.command // ""' "$state_file")
  start_line=$(jq -r '.start_line // 0' "$state_file")
  [ -z "$transcript_path" ] && transcript_path=$(jq -r '.transcript_path // ""' "$state_file")
fi

duration=""
if [ -n "$start_time" ]; then
  start_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_time" "+%s" 2>/dev/null || date -u -d "$start_time" "+%s" 2>/dev/null || echo "")
  end_epoch=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$end_time" "+%s" 2>/dev/null || date -u -d "$end_time" "+%s" 2>/dev/null || echo "")
  if [ -n "$start_epoch" ] && [ -n "$end_epoch" ]; then
    duration=$((end_epoch - start_epoch))
  fi
fi

input_tokens=0
output_tokens=0
cache_creation=0
cache_read=0
model="unknown"
category="chat-only"
category_detail=""

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # Categorization is derived from what the transcript shows actually
  # happened this turn (which tools ran), not from guessing at the prompt
  # text — a free-form prompt that triggers /speckit.implement's Skill call is
  # "skill:speckit.implement" the same as if the user had typed the slash command.
  turn_json=$(tail -n "+$((start_line + 1))" "$transcript_path" | jq -s '
    . as $events
    | (map(select(.type == "assistant" and .message.usage != null))) as $assist_usage
    | ($events | map(select(.type == "assistant")) | map(.message.content // []) | flatten(1) | map(select(.type == "tool_use"))) as $tool_uses
    | {
        totals: (reduce $assist_usage[] as $item ({"input":0,"output":0,"cache_creation":0,"cache_read":0};
          .input += ($item.message.usage.input_tokens // 0)
          | .output += ($item.message.usage.output_tokens // 0)
          | .cache_creation += ($item.message.usage.cache_creation_input_tokens // 0)
          | .cache_read += ($item.message.usage.cache_read_input_tokens // 0)
        )),
        model: ($assist_usage | map(.message.model) | map(select(. != null)) | last),
        category: (
          def top: group_by(.) | max_by(length) | .[0];
          ($tool_uses | map(select(.name == "Skill")) | map(.input.skill // "unknown")) as $skills
          | ($tool_uses | map(select(.name == "Agent")) | map(.input.subagent_type // "general-purpose")) as $agents
          | ($tool_uses | map(select(.name == "Workflow")) | map(.input.name // "inline-script")) as $workflows
          | ($tool_uses | map(select(.name == "Edit" or .name == "Write" or .name == "NotebookEdit"))) as $edits
          | ($tool_uses | map(select(.name == "Bash"))) as $bashes
          | ($tool_uses | map(select(.name == "Read" or .name == "Grep" or .name == "Glob" or .name == "WebFetch" or .name == "WebSearch"))) as $reads
          | if ($skills | length) > 0 then {category: "skill", detail: ($skills | top)}
            elif ($agents | length) > 0 then {category: "agent", detail: ($agents | top)}
            elif ($workflows | length) > 0 then {category: "workflow", detail: ($workflows | top)}
            elif ($edits | length) > 0 then {category: "code-edit", detail: ""}
            elif ($bashes | length) > 0 then {category: "shell", detail: ""}
            elif ($reads | length) > 0 then {category: "research", detail: ""}
            elif ($tool_uses | length) == 0 then {category: "chat-only", detail: ""}
            else {category: "other-tool-use", detail: ""}
            end
        )
      }
  ' 2>/dev/null || echo '{"totals":{"input":0,"output":0,"cache_creation":0,"cache_read":0},"model":null,"category":{"category":"unknown","detail":""}}')

  input_tokens=$(echo "$turn_json" | jq -r '.totals.input // 0')
  output_tokens=$(echo "$turn_json" | jq -r '.totals.output // 0')
  cache_creation=$(echo "$turn_json" | jq -r '.totals.cache_creation // 0')
  cache_read=$(echo "$turn_json" | jq -r '.totals.cache_read // 0')
  model=$(echo "$turn_json" | jq -r '.model // "unknown"')
  category=$(echo "$turn_json" | jq -r '.category.category // "unknown"')
  category_detail=$(echo "$turn_json" | jq -r '.category.detail // ""')
fi

# Which child product repository an ide-event path belongs to, so idle IDE
# noise (a file opened, a selection changed) can still be attributed to an
# area of work instead of being one undifferentiated "ide-event" bucket.
detect_repo() {
  case "$1" in
    *MyIsn.Android*) echo "android" ;;
    *MyIsn.iOS*) echo "ios" ;;
    *Mockoon*) echo "mockoon" ;;
    */empower/*) echo "hub" ;;
    *) echo "other" ;;
  esac
}

# Refine the no-tool-use fallback using the prompt text itself: distinguish
# pure IDE-context noise and background-task pickups from an actual plain
# chat reply, and catch slash commands that don't route through the Skill
# tool (e.g. built-in commands with no matching Skill entry).
if [ "$category" = "chat-only" ]; then
  case "$command" in
    '<ide_opened_file>'*) category="ide-event"; category_detail="file-opened:$(detect_repo "$command")" ;;
    '<ide_selection>'*) category="ide-event"; category_detail="selection:$(detect_repo "$command")" ;;
    '<task-notification>'*) category="task-notification" ;;
    '/'*) category="slash-command"; category_detail=$(echo "$command" | awk '{print $1}' | tr -d '"') ;;
  esac
fi

total=$((input_tokens + output_tokens + cache_creation + cache_read))

# Reasoning effort for the session (low/medium/high/xhigh), set by the harness.
effort_level="${CLAUDE_EFFORT:-unknown}"

# Local daily token budget: sum today's rows already in the CSV, plus this one.
today=$(echo "$start_time" | cut -dT -f1)
daily_prior=0
if [ -f "$csv_file" ] && [ -n "$today" ]; then
  daily_prior=$(python3 -c '
import csv, sys
today = sys.argv[2]
total = 0
with open(sys.argv[1], newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        if row.get("start_time", "").startswith(today):
            try:
                total += int(float(row.get("total_tokens") or 0))
            except ValueError:
                pass
print(total)
' "$csv_file" "$today" 2>/dev/null || echo 0)
fi
daily_tokens_so_far=$((daily_prior + total))
daily_limit_reached="false"
if [ "$daily_tokens_so_far" -ge "$daily_limit_tokens" ]; then
  daily_limit_reached="true"
fi

escaped_user=$(echo "$user" | sed 's/"/""/g')
escaped_command=$(echo "$command" | sed 's/"/""/g')
escaped_category_detail=$(echo "$category_detail" | sed 's/"/""/g')

echo "\"$start_time\",\"$end_time\",\"$duration\",\"$session_id\",\"$escaped_user\",\"$escaped_command\",\"$model\",\"$effort_level\",\"$category\",\"$escaped_category_detail\",$input_tokens,$output_tokens,$cache_creation,$cache_read,$total,$daily_tokens_so_far,$daily_limit_tokens,$daily_limit_reached" >> "$csv_file"

rm -f "$state_file"
