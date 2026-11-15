# Stage 05 Worksheet 3: An ephemeral dust anchor

**Output:** a mined 0-fee parent with a 0-value output and its child; answers in "Worksheet 3".
**Checker:** `./check_truc.sh`

Read `src/policy/ephemeral_policy.h` (the comment block at the top) and
`test/functional/mempool_ephemeral_dust.py` (its first test case) before you start.

## Step 1 — the parent
Build **E**: version 3, one mature input, two outputs: (a) almost the whole value to a miner
address, (b) **0.00000000** BTC to another miner address. Fee 0. Sign it.
`testmempoolaccept` it alone → `E_ALONE_REASON`.

## Step 2 — the child that spends the dust
Build **EC**: version 3, spending **both** E outputs (or at least the dust one), one output, fee
of 5,000 sat. `submitpackage [E, EC]`. Record `E_TXID`, `EC_TXID`.

## Step 3 — the failure you should see once
Build a different child that spends only E's **non-dust** output and submit `[E, that child]`
instead (do this **before** Step 2). Record two things: the package-level `package_msg` as
`UNSPENT_DUST_PKG_MSG`, and the child's own `error` in `tx-results` (the part before the first
comma) as `MISSING_SPEND_REASON`.

<details><summary>Hint</summary>

Search `ephemeral_policy.cpp` for the reason string that starts with `missing-`.
</details>

## Step 4 — mine
Mine one block with E and EC. In your journal: why does this rule keep the UTXO set clean, and
why must E pay exactly 0 fee? (Read the rationale comment in `ephemeral_policy.h`.)
