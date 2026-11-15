#!/usr/bin/env bash
# check_commit_hygiene.sh: outcome checker for Stage 19 exercise 4 (your own branch, your own clone).
# Usage: bash 19-review-and-contribution-practicum/check_commit_hygiene.sh <repo-path> <base>..<branch>
#
# Read-only: it only runs `git log` / `git rev-list` against the repo you name. Checks every commit for:
#   - subject <= 50 chars, starts with a known area prefix ("area: ..." or "scripted-diff: ...")
#   - blank second line, and a body (unless the subject is very short and self-explanatory)
#   - no @mentions anywhere in the message (CONTRIBUTING.md)
#   - no AI-agent author/co-author trailers (doc/AI_POLICY.md)
#   - not a merge commit
#   - signed with a good signature (%G? is G or U)
# It reports what is wrong; it does not rewrite anything.
set -u

if [ $# -ne 2 ]; then
  echo "usage: $0 <repo-path> <base>..<branch>"; exit 2
fi
REPO="$1"; RANGE="$2"

if [ "$(cd "$REPO" 2>/dev/null && pwd)" = "/Users/mac/bitcoin" ]; then
  echo "NOTE: /Users/mac/bitcoin is the lab's reference checkout. Practise on your fork's clone instead."
fi

git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || { echo "FAIL: $REPO is not a git repo"; exit 2; }
commits=$(git -C "$REPO" rev-list --reverse "$RANGE" 2>/dev/null) || { echo "FAIL: bad range $RANGE"; exit 2; }
[ -n "$commits" ] || { echo "FAIL: range $RANGE has no commits"; exit 1; }

# Prefixes from CONTRIBUTING.md "Creating the Pull Request" plus common subsystem prefixes seen in git log.
PREFIX_RE='^(scripted-diff|consensus|doc|docs|qt|gui|log|logging|mining|net|p2p|refactor|rpc|rest|zmq|contrib|cli|test|qa|ci|util|lib|wallet|build|cmake|guix|depends|fuzz|bench|policy|mempool|validation|kernel|index|txgraph|clusterlin|coins|script|sign|psbt|crypto|random|http|addrman|net_processing|init|node|interfaces|ipc|lint|tracing|subprocess|common|key|descriptors|txmempool|chain|blockstorage|bitcoin-tx|bitcoin-cli|bitcoin-wallet|bitcoin-util)(, ?[a-z0-9_-]+)*:( \[[^]]+\])? [^ ]'

total=0; bad=0
for c in $commits; do
  total=$((total+1))
  short=$(git -C "$REPO" rev-parse --short=10 "$c")
  subj=$(git -C "$REPO" log -1 --format=%s "$c")
  msg=$(git -C "$REPO" log -1 --format=%B "$c")
  line2=$(printf '%s\n' "$msg" | sed -n 2p)
  bodylines=$(printf '%s\n' "$msg" | sed -n '3,$p' | grep -v -E '^[[:space:]]*$' | wc -l | tr -d ' ')
  parents=$(git -C "$REPO" log -1 --format=%P "$c" | wc -w | tr -d ' ')
  sig=$(git -C "$REPO" log -1 --format=%G? "$c")
  problems=()

  [ "$parents" -le 1 ] || problems+=("merge commit: rebase instead of merging (CONTRIBUTING.md 'Rebasing Changes')")
  [ ${#subj} -le 50 ] || problems+=("subject is ${#subj} chars; CONTRIBUTING.md says 50 max")
  printf '%s' "$subj" | grep -q -E "$PREFIX_RE" || problems+=("subject lacks an area prefix like 'test: ' or 'wallet: ' (see CONTRIBUTING.md list)")
  if [ -n "$line2" ]; then problems+=("second line must be blank"); fi
  if [ "$bodylines" -eq 0 ] && [ ${#subj} -gt 35 ]; then
    problems+=("no body: explain WHY in the body (subject alone is only OK for self-explanatory changes)")
  fi
  printf '%s' "$msg" | grep -q -E '(^|[[:space:]])@[A-Za-z0-9-]+' && problems+=("contains an @mention; never put @ in commit messages")
  if printf '%s' "$msg" | grep -i -E '^(co-authored-by|signed-off-by|generated-by|assisted-by):' | grep -q -i -E 'claude|anthropic|copilot|openai|chatgpt|gpt|gemini|cursor|codex|devin|agent|\bbot\b|noreply@'; then
    problems+=("AI/agent author trailer present; doc/AI_POLICY.md: do not include agents as authors or co-authors")
  fi
  author=$(git -C "$REPO" log -1 --format='%an <%ae>' "$c")
  printf '%s' "$author" | grep -q -i -E 'claude|copilot|openai|\[bot\]' && problems+=("author looks like an agent/bot: $author")
  case "$sig" in
    G|U) : ;;
    N) problems+=("not signed (configure GPG or SSH signing, then re-sign)") ;;
    *) problems+=("signature status '$sig' is not good (git log --show-signature to see why)") ;;
  esac

  if [ ${#problems[@]} -eq 0 ]; then
    echo "PASS $short $subj"
  else
    bad=$((bad+1))
    echo "FAIL $short $subj"
    for p in "${problems[@]}"; do echo "     - $p"; done
  fi
done

echo "----"
echo "$((total-bad))/$total commits pass."
echo "Not checked here (do it yourself): each commit builds and passes tests on its own; commits are atomic; no mixed move+change."
[ $bad -eq 0 ]
