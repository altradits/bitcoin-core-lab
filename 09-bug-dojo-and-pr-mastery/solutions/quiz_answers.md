# Stage 09 quiz answers (spoilers)

1. A single huge or negative output can make the 64-bit sum wrap around to a small or negative number that then passes the total check (CVE-2010-5139). Checking each value in [0, MAX_MONEY] first means the sum of at most N such values cannot overflow before the total check.
2. In 2017 (PR #9049) the duplicate-input check in `CheckTransaction` was skipped during block validation for speed, on the assumption that the later UTXO lookup would catch it. A tx spending the same output twice in one block would hit an assertion (crash) and, for outputs created in the same block, could inflate supply. Fixed in 0.16.3 (CVE-2018-17144).
3. 16 to 64 bytes inclusive (128–512 bits).
4. `vsize = ceil(max(weight, sigop_cost × 20) / 4)`; `DEFAULT_BYTES_PER_SIGOP` = 20.
5. Integer division and floats lose precision; a·d > c·b is exact for positive sizes and needs no rounding decisions.
6. 1 (reject), 2 (accept), 100 (accept), 101 (reject).
7. A mutant is a small deliberate change to the code under test (e.g. `>` → `>=`). If no test fails on it, the tests do not pin that behaviour. A test that cannot fail gives false confidence to reviewers.
8. `git log -S'<text>' -- <file>` (pickaxe), `git blame -L <a>,<b> <file>`, then `git show <commit>` and find the merge commit and PR number with `git log --merges --ancestry-path <commit>..master | tail -1`.
