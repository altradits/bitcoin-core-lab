#!/usr/bin/env bash
# check_gauntlet.sh: outcome checker for Stage 19 Review Gauntlet rounds.
# Usage: bash 19-review-and-contribution-practicum/check_gauntlet.sh [G01 ... G10]   (no args = all)
#
# For each round it checks the learner's own files in my-work/19/gauntlet/:
#   Gxx-<PR>-blind.md   : parent + head commit lines are correct, required sections are filled,
#                         template blanks are gone
#   Gxx-<PR>-compare.md : Sealed-SHA256 matches the blind file (blind file unchanged since sealing),
#                         rubric R1..R9 answered and scored
# It never prints the expected commits. They are stored only as truncated SHA-256 digests.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/my-work/19/gauntlet"

# round  pr  sha256(parent)[0:16]  sha256(head)[0:16]
ROUNDS=(
  "G01 36231 977e98d56ed5ed71 f90cae6209fc4543"
  "G02 36703 2f009f1db8b7e690 67ce14bcbfefeb2d"
  "G03 36535 231548dc1853a8dc 7c01493d1bc77d76"
  "G04 36682 f218524215c8b6fb fd784a16976cef84"
  "G05 36397 5455d126f3693f9b d710157bd617680b"
  "G06 36368 bdd2d208c2bf4d9c 5a2004558529acb6"
  "G07 35989 c6ea5413bc661345 3c3d6ac678f9e247"
  "G08 35984 a3c601bf67abaf57 c0eb03e8b80c6f0c"
  "G09 36080 2b1fadadd118ec9f 759155bc2121b273"
  "G10 970 4b130dd3646cf2b1 fd7f20cb1b98949c"
)

digest() { printf %s "$1" | shasum -a 256 | cut -c1-16; }

# Print the text under a "## <name>" heading up to the next "## " heading (comments and blanks removed).
section() {
  awk -v want="$2" '
    /^## / { insec = (index($0, want) > 0); next }
    insec { print }
  ' "$1" | sed -e 's/<!--.*-->//g' | grep -v -E '^[[:space:]]*-?[[:space:]]*$' || true
}

fails=0; checked=0
want=("$@")

for row in "${ROUNDS[@]}"; do
  read -r R PR PDIG HDIG <<<"$row"
  if [ ${#want[@]} -gt 0 ]; then
    match=0; for w in "${want[@]}"; do [ "$w" = "$R" ] && match=1; done
    [ $match -eq 1 ] || continue
  fi
  checked=$((checked+1))
  blind="$DIR/$R-$PR-blind.md"; cmp="$DIR/$R-$PR-compare.md"
  errs=()

  if [ ! -f "$blind" ]; then
    errs+=("missing $blind (copy exercises/templates/gauntlet-blind.md)")
  else
    p=$(grep -m1 -i '^Parent commit' "$blind" | grep -o -E '[0-9a-f]{40}' | head -1)
    h=$(grep -m1 -i '^PR head commit' "$blind" | grep -o -E '[0-9a-f]{40}' | head -1)
    [ -n "$p" ] || errs+=("blind: 'Parent commit' line has no full 40-hex hash")
    [ -n "$h" ] || errs+=("blind: 'PR head commit' line has no full 40-hex hash")
    [ -n "$p" ] && [ "$(digest "$p")" != "$PDIG" ] && errs+=("blind: parent commit is not the merge commit's first parent; re-derive it")
    [ -n "$h" ] && [ "$(digest "$h")" != "$HDIG" ] && errs+=("blind: head commit is not the merged PR head (merge commit's second parent)")
    for s in "Motivation" "Tests I ran" "Break attempt" "Commit-by-commit" "My verdict"; do
      n=$(section "$blind" "$s" | wc -l | tr -d ' ')
      [ "$n" -ge 1 ] || errs+=("blind: section '$s' is empty")
    done
    grep -q '____' "$blind" && errs+=("blind: template blanks (____) still present")
  fi

  if [ ! -f "$cmp" ]; then
    errs+=("missing $cmp (write it only after sealing the blind file)")
  elif [ -f "$blind" ]; then
    sealed=$(grep -m1 '^Sealed-SHA256:' "$cmp" | grep -o -E '[0-9a-f]{64}' | head -1)
    actual=$(shasum -a 256 "$blind" | cut -d' ' -f1)
    if [ -z "$sealed" ]; then
      errs+=("compare: no Sealed-SHA256 line with a 64-hex digest")
    elif [ "$sealed" != "$actual" ]; then
      errs+=("compare: blind file changed after sealing (digest mismatch). Blind reviews stay as written.")
    fi
    for i in 1 2 3 4 5 6 7 8 9; do
      line=$(grep -m1 -E "^## R$i " "$cmp" || true)
      if [ -z "$line" ]; then errs+=("compare: heading for R$i missing"); continue; fi
      echo "$line" | grep -q -E 'score [0-2]/2' || errs+=("compare: R$i not scored (write 'score 0/2', '1/2' or '2/2')")
      n=$(section "$cmp" "R$i " | wc -l | tr -d ' ')
      [ "$n" -ge 1 ] || errs+=("compare: R$i has no answer")
    done
  fi

  if [ ${#errs[@]} -eq 0 ]; then
    echo "PASS $R (#$PR)"
  else
    fails=$((fails+1))
    echo "FAIL $R (#$PR)"
    for e in "${errs[@]}"; do echo "     - $e"; done
  fi
done

[ $checked -gt 0 ] || { echo "No matching rounds. Use G01..G10."; exit 2; }
echo "----"
echo "$((checked-fails))/$checked rounds pass."
[ $fails -eq 0 ]
