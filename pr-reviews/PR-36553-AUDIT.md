# Audit: bitcoin/bitcoin#36553 `test: Add missing sync_mempools in wallet_conflicts.py`

* URL: https://github.com/bitcoin/bitcoin/pull/36553
* Author: @maflcko
* State: MERGED on 2026-10-20 (merge commit `020fcb281ebccdeaf6b8856964e545e9073d64df`)
* Audited head: `fa1061481bb1cb6bb7d5ca7ea6674f349f2baed8`
* Checked: 2026-11-06
* Risk: test only. No consensus, P2P, or wallet behavior change.

> **Study notes.** Header and review notes were checked by hand against GitHub on the date shown;
> recheck open PRs before citing them. Sections 5–6 are blank for you to complete after your own review.
> See [`README.md`](./README.md) for known issues.


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

## 5. Review checklist (YOURS to tick — nothing below was checked for you)
- [ ] **1. Risk area:** Which subsystem and invariant does this PR touch? Is any consensus behaviour affected? (Decide yourself.)
- [ ] **2. Invariants:** Which invariants must hold (supply, UTXO conservation, policy limits, determinism)? How did you check them?
- [ ] **3. Bounds:** Integer overflow/underflow, unbounded containers or loops reachable by a peer or RPC caller?
- [ ] **4. Locking:** Which mutexes are taken; do the annotations (`EXCLUSIVE_LOCKS_REQUIRED`, `GUARDED_BY`) still hold?
- [ ] **5. Adversarial input:** Can an untrusted peer or caller make the node do expensive work?
- [ ] **6. Tests:** Do the PR's tests fail without the change (mutation)? What did you run, on which commit?

## 6. Your conclusion (fill in from YOUR OWN testing; never post text you did not write)
- Commit I reviewed: `________`
- What I built and ran (exact commands): ________
- What I tested manually beyond the PR's tests: ________
- Questions / concerns for the author: ________
- My conclusion (Concept/Approach/Code review, or none yet): ________

> Bitcoin Core's `doc/AI_POLICY.md` (master) and `CONTRIBUTING.md` expect review comments to be your
> own work. This file is study material, not a comment to paste.

<details><summary>Lab notes (spoiler: open only after your own review)</summary>

Correct test stability fix. No further action.

</details>
