# Stage 03 Worksheet 3: CPFP — pull a stuck parent into a block

**Output:** a low-fee parent and a child that pays for it, mined in one block; answers in "Worksheet 3".
**Checker:** `./03-rbf-and-cpfp/check_cpfp.sh`

## Step 1 — a stuck parent
Build **PARENT**: one mature `kisumu_miner` input, `1.00000000` BTC to a new `kisumu_merchant`
address, change back to the miner, fee giving a feerate between **1.0 and 2.0 sat/vB**.
Broadcast it. Do **not** mine. Record `PARENT_TXID`, `PARENT_FEE_SATS`, `PARENT_VSIZE`.

## Step 2 — compute the child fee on paper
Target: a **package feerate of at least 50 sat/vB**. The merchant spends its 1 BTC output to a
single new merchant address (1 input, 1 output, P2WPKH).
1. Predict `CHILD_VSIZE` (1-in-1-out P2WPKH — work it out from the Stage 02 byte layout).
2. `CHILD_FEE_SATS = ceil(50 × (PARENT_VSIZE + CHILD_VSIZE)) − PARENT_FEE_SATS`.
3. Predict `PKG_FEE_SATS`, `PKG_VSIZE` and `PKG_FEERATE_SAT_VB` (2 decimals).

<details><summary>Hint 1</summary>

A P2WPKH input is 41 bytes of base data plus a witness of ~108 bytes; a P2WPKH output is 31
bytes. Add version, counts, marker/flag and locktime. Then weight → vsize (round up).
</details>

## Step 3 — build, test, broadcast the child
Build **CHILD** from the merchant wallet: the input is `PARENT_TXID` output that pays the
merchant (find its index — do not assume 0). Before broadcasting, run `getmempoolentry` on the
parent; after broadcasting, run it on both. Copy `ancestorsize` and `fees.ancestor` of the child
into your journal and compare with your predictions. Record `CHILD_TXID`.

<details><summary>Hint 2</summary>

`signrawtransactionwithwallet` can sign an input whose parent is unconfirmed, because the
wallet already knows the parent. If the merchant wallet does not know it, check that you
broadcast PARENT to the same node.
</details>

## Step 4 — mine and confirm the order
Mine **one** block. Record `CPFP_BLOCK_HEIGHT`. With `getblock <hash> 1`, confirm that the parent
appears **before** the child in the `tx` array. Why must it? (Consensus: an input can only spend
an output that exists earlier — in a previous block or earlier in the same block.)

## Stretch (no checker)
Make a parent with **0 sat** fee and try to broadcast it alone. What happens? Then read
`doc/policy/packages.md` and Stage 05 to see how package relay (`submitpackage`) fixes this.
