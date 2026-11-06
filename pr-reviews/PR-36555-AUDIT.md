# Audit: bitcoin/bitcoin#36555 `rpc: return error when invalidateblock fails`

* URL: https://github.com/bitcoin/bitcoin/pull/36555
* Author: @ja7ad
* State: OPEN (no formal ACK yet). Checked: 2026-11-06. Recheck
  before citing: open PRs change.
* Audited head: `4aeb6a8fad7ad1f0efccf11e684e935e0a7d0320`
* Risk: RPC behavior change plus validation error plumbing. No
  consensus change. Callers that relied on silent `null` will now see
  errors, which is the intended fix.

## What the PR does

`invalidateblock` returned `null` (success) even when the block could
not be invalidated, for example when rollback stopped at a block
without undo data and left the chain partially rolled back. The PR
routes both failure paths through `BlockValidationState`, rejects the
genesis block explicitly at the RPC layer, and covers each case with
tests plus release notes.

## Commits (3)

```text
77d45171d5 validation: report InvalidateBlock failures
b21ad96e3d validation: report InvalidateBlock failures through state
4aeb6a8fad rpc: return an error when invalidateblock fails
```

## Diff (6 files)

* `src/validation.cpp` (+5 -2): both `InvalidateBlock` failure
  returns become `state.Error(...)` with the block hash and the
  height the chain rolled back to.
* `src/rpc/blockchain.cpp` (+3): `invalidateblock` on height 0 throws
  `RPC_INVALID_PARAMETER` ("Cannot invalidate genesis block").
* `src/test/blockchain_tests.cpp` (+10 -1): asserts the return value
  and state validity, and adds a partial rollback case (undo data
  stripped from one block).
* `test/functional/rpc_invalidateblock.py` (+4): asserts error -8 on
  the genesis block.
* `doc/release-notes-36555.md` (+9, new): documents the behavior change.
* `CMakeLists.txt` (+2 -1): adds `src/pubkey.cpp` to
  `core_interface`. Review question: this looks unrelated to the
  fix. Confirm whether the unit test needs the new link or whether
  the hunk is a leftover.

## Review notes

* @pinheadmz asked for AI policy confirmation and a fuller PR
  description before review.
* @l0rinc suggested reproducing the partial rollback with AssumeUTXO
  instead of manual file corruption.
* @yusufyildiz34 reviewed the diff without building: concept sound,
  asked that the error print the block the check is about. The
  author adopted `to_mark_failed` in the message and moved the
  genesis rejection to the RPC layer with -8.
* No formal ACK at check time.

## Verdict

Well scoped error propagation fix with tests at both layers. Open
questions for a student reviewer: justify or drop the CMakeLists
hunk, and run `rpc_invalidateblock.py` plus the `invalidate_block`
unit test on the branch.
