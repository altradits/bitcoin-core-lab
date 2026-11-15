# Stage 03 Worksheet 1: RBF by hand — fail rule 4, then replace

**Output:** two transactions on your node, one rejected attempt, answers in `answers.env` (section "Worksheet 1").
**Checker:** `./03-rbf-and-cpfp/check_rbf.sh`

Read first: `bitcoin-cli help createrawtransaction`, `help testmempoolaccept`,
`help getmempoolentry`, `help getnetworkinfo` (find `incrementalfee`), and
`doc/policy/mempool-replacements.md` in your Core checkout.

## Step 1 — the original (V1)
Build, sign and broadcast **V1**:
- one input: a mature `kisumu_miner` UTXO;
- outputs: `2.00000000` BTC to a new `kisumu_merchant` address, change to a new `kisumu_miner` change address;
- explicit `nSequence = 0xfffffffd` on the input (BIP125 signal; Worksheet 2 drops it);
- fee: exactly **200 sat**. (Your node's minimum relay feerate is 1 sat/vB on v29; work out on paper whether 200 sat clears it for this tx shape.)

Record `V1_TXID`, `V1_FEE_SATS`, `V1_VSIZE` (from `getmempoolentry`).

<details><summary>Hint 1 (concept)</summary>

`nSequence` is per input. In the inputs JSON of `createrawtransaction` an input object can carry a
`sequence` key. Write `0xfffffffd` as a decimal number.
</details>

## Step 2 — predict the minimum replacement fee
On paper, before you build anything:
1. Read `incrementalfee` from `getnetworkinfo` (BTC/kvB) → convert to sat/vB.
2. A replacement with the **same shape** has (almost) the same vsize. Write
   `MIN_REPLACEMENT_FEE_SATS = V1_FEE_SATS + ceil(incremental_sat_per_vB × replacement_vsize)`.
3. Which rule sets this bound? → `RULE_FOR_MIN_ADDITIONAL`.

## Step 3 — the replacement that fails (BAD)
Build a replacement that spends the **same** input with the same two outputs, but whose fee is
only **250 sat** (+50). Run `testmempoolaccept` on it (do not broadcast).
Record `BAD_REJECT_REASON` exactly as printed (the short reason, not the long message) and the
two numbers in the long message as `BAD_ADDITIONAL_SATS` and `BAD_REQUIRED_SATS` (in sat).

<details><summary>Hint 1</summary>

Lower the change output by 50 sat compared with V1. Everything else stays the same.
</details>
<details><summary>Hint 2</summary>

`testmempoolaccept` returns `reject-reason` and, from v28, `reject-details`. The long message
prints amounts in BTC; multiply by 100,000,000.
</details>

## Step 4 — the replacement that wins (V2)
Build **V2** paying exactly **5,000 sat** total. `testmempoolaccept` first, then broadcast.
Then prove V1 is gone (which RPC errors, and with what message?).
Record `V2_TXID`, `V2_FEE_SATS`, `V2_VSIZE`.

## Step 5 — explain in your journal
In your own words (3–5 sentences): why does rule 4 use the **replacement's** vsize and not the
original's? What would go wrong if rule 4 did not exist?

Then mine one block and leave the merchant's 2 BTC output **unspent** until Worksheet 3? No —
Worksheet 3 needs an *unconfirmed* parent, so you will create a fresh one there. You may mine now.
