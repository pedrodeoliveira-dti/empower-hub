#!/bin/bash
# SessionStart hook: fetch each child repo's origin/master and report how many
# commits master is behind, so a fresh hub session can offer to pull before
# any work starts. Never pulls automatically.
cd "$CLAUDE_PROJECT_DIR" || exit 0

REPOS="MyIsn.Android MyIsn.iOS Mockoon"
SUMMARY=""

for r in $REPOS; do
  [ -d "$r/.git" ] || continue
  git -C "$r" fetch origin master --quiet 2>/dev/null || continue
  BEHIND=$(git -C "$r" rev-list --count master..origin/master 2>/dev/null)
  if [ -n "$BEHIND" ] && [ "$BEHIND" -gt 0 ] 2>/dev/null; then
    SUMMARY="${SUMMARY}- ${r}: ${BEHIND} new commit(s) on origin/master not yet in local master
"
  fi
done

if [ -n "$SUMMARY" ]; then
  CONTEXT="Upstream check (Azure DevOps) at session start:
${SUMMARY}
Tell the user which repos and how many commits, then ask if they want to pull master for each (e.g. git -C <repo> pull origin master, or checkout master first if a different branch is checked out). Never pull automatically."
  python3 -c "
import json, sys
context = sys.stdin.read()
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'SessionStart', 'additionalContext': context}}))
" <<< "$CONTEXT"
fi
exit 0
