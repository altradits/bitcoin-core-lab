# Stage 05 Worksheet 1: Zero-fee TRUC parent — alone, wrong child, right child

**Output:** an accepted 1P1C TRUC package; answers in "Worksheet 1". **Checker:** `./check_truc.sh`

Read first: `bitcoin-cli help submitpackage`, `doc/policy/packages.md`, `src/policy/truc_policy.h`.

## Step 1 — make a v3 parent by hand
1. With `createrawtransaction`, build **P**: one mature `kisumu_miner` input, **two** outputs to
   `kisumu_miner` addresses (you need the second one in Worksheet 2), and **0 fee** (outputs sum to
   exactly the input value).
2. `createrawtransaction` on v29 has no version argument. Decode the hex: the first 4 bytes are the
   version, little-endian. Change them so the tx is version 3. Write the old and new first 8 hex
   characters in your journal. Decode again to confirm `"version": 3`.
3. Sign it. Record `P_TXID`.

<details><summary>Hint 1</summary>

Version 2 little-endian is `02000000`. Shell string slicing (`${HEX:8}`) gives you everything
after the first 4 bytes. Master's `createrawtransaction` has a `version` argument; v29's does not.
</details>

## Step 2 — the parent alone
`testmempoolaccept` on P. Record `P_ALONE_REASON` (the short `reject-reason`).

## Step 3 — a v2 child (wrong)
Build child **C2** with version **2** spending P's output 0 and paying a fee of 10,000 sat. You
must give `signrawtransactionwithwallet` the parent's output (`prevtxs`) because P is not in any
mempool. `submitpackage` the pair `[P, C2]`. Record the first word of `package_msg` (the
violation name, before the comma) as `V2_CHILD_ERROR`.

<details><summary>Hint 2 (prevtxs)</summary>

`prevtxs` is an array of objects with `txid`, `vout`, `scriptPubKey`, `amount`. Read them from
`decoderawtransaction` of P.
</details>

## Step 4 — a v3 child (right)
Build **C3**: version **3**, spending P's output 0, 10,000-sat fee, one output. On paper first:
the package feerate = 10,000 / (vsize(P) + vsize(C3)). Record `PKG_FEERATE_PREDICTED_SAT_VB`
(2 decimals). `submitpackage [P, C3]`. Record `C3_TXID` and the `effective-feerate` you got,
converted to sat/vB, as `PKG_EFFECTIVE_FEERATE_SAT_VB`.

Do **not** mine yet; Worksheet 2 continues with P in the mempool.
