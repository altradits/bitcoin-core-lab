# Stage 05 Worksheet 2: Sibling eviction

**Output:** a second TRUC child that replaced C3; answers in "Worksheet 2". **Checker:** `./check_truc.sh`

P (in the mempool from Worksheet 1) already has one child, C3. TRUC allows only one.

## Step 1 — predict
A new v3 child **S** spends P's **output 1** (a different outpoint, so it does *not* conflict
with C3 directly). In your journal: what should happen under v2 rules? Under TRUC
(`TRUC_DESCENDANT_LIMIT` = 2)? What must S pay to evict C3 (rules 3 and 4 of Stage 03, with C3's
fee as the "original" fee)? Record `S_MIN_FEE_SATS`.

## Step 2 — too cheap
Build S with a fee **below** C3's fee and `testmempoolaccept` it. Record `reject-reason` exactly (it is longer than in Stage 03)
as `S_CHEAP_REASON`.

<details><summary>Hint</summary>

Compare with Stage 03: it is the same fee rule, but the node tells you it considered evicting
the sibling. Find the format string in `src/validation.cpp` (search `sibling_eviction`).
</details>

## Step 3 — evict
Build S paying at least `S_MIN_FEE_SATS`, broadcast it, and show C3 is gone. Record `S_TXID`.
Then mine one block and confirm P and S are in it.

## Step 4 — journal
Why is sibling eviction safe for TRUC but would be dangerous for normal v2 transactions?
(Think: how big can the evicted sibling be?)
