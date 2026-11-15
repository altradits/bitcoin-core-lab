# Stage 15 Exercise 2: Reorg drill on regtest

**Output:** answers in `my-work/15-validation-chainstate-and-reorgs/answers.env`.
**Checker:** `./15-validation-chainstate-and-reorgs/check_15.sh reorg` (asks your node; `BTC_CLI` as before)

Use your Stage 01 regtest node with the `kisumu_miner` and `kisumu_merchant` wallets.

## Step 1 — a transaction in a block you will undo
1. Send 1 BTC from `kisumu_miner` to a new `kisumu_merchant` address. Record `REORG_TXID`.
2. Mine **one** block containing it. Record its hash as `ORPHANED_BLOCK` and height as `FORK_HEIGHT`.
3. Mine **two** more blocks on top. Record the tip as `OLD_TIP`.

## Step 2 — reorg away from it
1. `invalidateblock ORPHANED_BLOCK`. Predict first: what is the new height? Where is `REORG_TXID` now?
2. Check `getmempoolentry REORG_TXID` and `getchaintips`. Record the `status` of the tip that
   contains `OLD_TIP` as `OLD_BRANCH_STATUS`.
3. Mine **four** new blocks (a longer competing chain) to a **new** address. Record the new tip as
   `NEW_TIP`. (Try it once with the *same* address within a second of invalidating: you may get
   `block not accepted`. Explain why in your journal — what is identical about the block you built?)
   Check where `REORG_TXID` is now (mempool or mined again in the new chain?).

## Step 3 — reconsider
1. `reconsiderblock ORPHANED_BLOCK`. Predict: does the node switch back to the old branch? Why/why not?
   (Compare chain work: old branch = fork + 3 blocks, new branch = 4 blocks from the fork parent.)
2. Record the active tip as `TIP_AFTER_RECONSIDER` and the old branch's status in `getchaintips`
   as `OLD_BRANCH_STATUS_AFTER`.

## Step 4 — journal
Explain each prediction you got wrong. Which function moved `REORG_TXID` back into the mempool?
