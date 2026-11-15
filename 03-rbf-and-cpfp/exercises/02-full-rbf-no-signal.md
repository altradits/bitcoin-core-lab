# Stage 03 Worksheet 2: Full-RBF — replace a transaction that does not signal

**Output:** a non-signalling transaction and its replacement; answers in "Worksheet 2".
**Checker:** `./03-rbf-and-cpfp/check_rbf.sh`

Under BIP125 alone this would be impossible. Since v28.0 Core accepts it by default. You will
prove that with your own node, and find where the change happened.

## Step 1 — a transaction that does NOT signal
Build **NS1**: one mature `kisumu_miner` input with `nSequence = 0xfffffffe` (final for BIP125
purposes, but still lets `nLockTime` work), one output to `kisumu_merchant`, change back,
fee 300 sat. Broadcast it.

Check what `getmempoolentry` prints for `bip125-replaceable`. Record it as
`NS1_BIP125_FIELD` (`true`/`false`).

## Step 2 — replace it anyway
Build **NS2** spending the same input with a fee that satisfies rules 3 and 4 (do the arithmetic
on paper). Broadcast it. Record `NS1_TXID` and `NS2_TXID`.

<details><summary>Hint 1</summary>

Same arithmetic as Worksheet 1 Step 2. If you get `txn-mempool-conflict`, your node is running
with full-RBF disabled — check your `bitcoin.conf` for an old `mempoolfullrbf=0` line (v29 still
accepts the option; master removed it).
</details>

## Step 3 — history
Find, in `doc/policy/mempool-replacements.md`, the Core version where full-RBF became the
default → `FULLRBF_DEFAULT_VERSION` (e.g. `25.0`) and the PR number → `FULLRBF_DEFAULT_PR`
(digits only).

In your journal: who benefits from full-RBF, who complained (zero-conf merchants), and why a
merchant in Kisumu accepting zero-conf payments must now wait for a confirmation or use
Lightning. Your words, not a copy of the mailing-list threads.
