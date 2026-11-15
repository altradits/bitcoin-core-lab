# Audit: bitcoin/bitcoin#36553 `test: Add missing sync_mempools in wallet_conflicts.py`

* URL: https://github.com/bitcoin/bitcoin/pull/36553
* Author: @maflcko
* State: MERGED on 2026-10-20 (merge commit `020fcb281ebccdeaf6b8856964e545e9073d64df`)
* Audited head: `fa1061481bb1cb6bb7d5ca7ea6674f349f2baed8`
* Checked: 2026-11-06
* Risk: test only. No consensus, P2P, or wallet behavior change.

## What the PR does

`test_mempool_conflict` in `wallet_conflicts.py` broadcasts three
transactions without syncing mempools between sends. The test assumed
every node sees the same replacement order, but a node that requests
an already replaced transaction ends up with a different set, making
the test fail intermittently. The fix calls `self.sync_mempools()`
after each send. A second commit removes two `sync_blocks()` calls
that became redundant after `self.generate` started syncing.

## Commits (2)

```text
fa3986f5c1 test: Remove redundant sync call after self.generate called sync_all
fa1061481b test: Add missing sync_mempools in wallet_conflicts.py
```

## Diff (1 file, +5 -4)

`test/functional/wallet_conflicts.py`: adds three
`self.sync_mempools()` calls in `test_mempool_conflict` and drops two
redundant `self.sync_blocks()` calls in `test_block_conflicts`.

## Review notes

* The failure mode is a test race, not a product bug. The added syncs
  match the pattern used across the functional suite.
* Merged with an ACK from @fanquake (`ACK fa1061481b...`).
* Nothing here affects node behavior. Safe to use as a first review
  exercise: check out the parent commit, run the test in a loop, and
  confirm the flake the PR describes.

## Verdict

Correct test stability fix. No further action.
