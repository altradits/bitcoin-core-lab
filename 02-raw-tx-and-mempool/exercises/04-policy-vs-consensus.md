# Stage 02 Worksheet 4: Policy vs consensus — make the node say "no" five ways

**Output:** answers in `answers.env` (section "Worksheet 4").
**Checker:** `./02-raw-tx-and-mempool/check_policy.sh`

**Do not broadcast any of these.** Use `testmempoolaccept` (it never relays). The only exception is
Task 1, where the point is to see `sendrawtransaction` refuse.

For every task, record the exact `reject-reason` (or error code) **and** classify the layer:
- `consensus` — a block containing this tx would be invalid for every node;
- `policy` — a valid block could contain it, but your node will not relay or mine it by default
  (standardness, fee rules, mempool limits);
- `rpc` — a safety check in the RPC/client only (the node never even evaluates policy or consensus).

| Task | Build this | Keys |
|------|------------|------|
| 1 | Spend a mature coinbase paying 1 BTC to the merchant and **no change** | `MAXFEE_ERROR_CODE`, `MAXFEE_TMA_REASON`, `MAXFEE_LAYER` |
| 2 | Pay **200 sat** to a P2WPKH address (and the rest as change) | `DUST_REASON`, `DUST_LAYER`, `DUST_THRESHOLD_P2WPKH_SATS` |
| 3 | Outputs worth **more** than the input | `BELOWOUT_REASON`, `BELOWOUT_LAYER` |
| 4 | An otherwise fine tx with **nLockTime = current height + 1** | `NONFINAL_LOCKTIME` (the value you used), `NONFINAL_REASON`, `NONFINAL_LAYER`, `LOCKTIME_FIRST_OK_TIP` |
| 5 | A fine tx whose **version is 4** (edit the hex by hand) | `VERSION_REASON`, `VERSION_LAYER` |

`MAXFEE_ERROR_CODE` is the numeric code `sendrawtransaction` prints; `MAXFEE_TMA_REASON` is what
`testmempoolaccept` says for the same tx with the default `maxfeerate`.

---

## Task notes and hints

**Task 1.** Compute the implicit fee and the implicit feerate (sat/vB) by hand first. Compare with
the default `maxfeerate` in `help sendrawtransaction` (unit: BTC/kvB). Then try it with
`testmempoolaccept` and `maxfeerate=0`. What does that tell you about the layer?

<details><summary>Hint 1</summary>

The default is `DEFAULT_MAX_RAW_TX_FEE_RATE` in `src/node/transaction.h`. Read
`BroadcastTransaction` in `src/node/transaction.cpp`: it first does a *test* acceptance (policy and
consensus pass!) and only then compares the fee with `max_tx_fee` and refuses. The error text mentions `-maxtxfee`, but that is a
**wallet** option; this RPC uses `maxfeerate`.
</details>

**Task 2.** Compute the dust threshold for a P2WPKH output at the default dust relay feerate by
hand using `GetDustThreshold` in `src/policy/policy.cpp` (`DUST_RELAY_TX_FEE` in
`src/policy/policy.h`). Write the threshold in the journal. Also read the `reject-details` text:
it mentions a 0-fee exception (ephemeral dust, `src/policy/ephemeral_policy.h`) — note it for Stage 05.

<details><summary>Hint 1</summary>

Dust threshold = the fee needed to *spend* the output at 3 sat/vB: (output size + the size of an
input spending it, with witness discount) × 3. For witness programs the input size is counted as
`32 + 4 + 1 + (107 / WITNESS_SCALE_FACTOR) + 4`.
</details>

**Task 3.** Your wallet will sign it. Why? (Signing does not check amounts add up — but which
sighash field *does* commit to the input amount?)

**Task 4.** Find the finality rule in `IsFinalTx` (`src/consensus/tx_verify.cpp`) and the height
the mempool passes to it (`CheckFinalTxAtTip` in `src/validation.cpp`). Then mine one block at a
time and find the lowest tip at which `testmempoolaccept` says `allowed: true` → `LOCKTIME_FIRST_OK_TIP`
(write it relative: e.g. if you built at tip T, is it T, T+1 or T+2? Write the absolute height.)

<details><summary>Hint 1</summary>

`createrawtransaction` has a `locktime` argument. A locktime only counts if at least one input's
nSequence is not `0xffffffff` — check what sequence your inputs got.
</details>
<details><summary>Hint 2</summary>

Locktimes below `LOCKTIME_THRESHOLD` (500,000,000; `src/script/script.h`) are block heights; above it
they are UNIX times compared with the **median time past** of the last 11 blocks (BIP113), not the
block's own timestamp. Find `GetMedianTimePast` in `ContextualCheckBlock`.
</details>

**Task 5.** The version is the first 4 bytes, little-endian. Change them in the *unsigned* hex, then
sign (why must you sign after editing?). Find `TX_MAX_STANDARD_VERSION` in `src/policy/policy.h`.
Journal: is a version-4 tx valid in a block? Who would have to change what for v4 to become standard?

---

## Wrap-up for the journal
Draw a two-column table "consensus | policy" and place: coinbase maturity (Stage 01), dust,
value-in < value-out, non-final, version 4, max-fee guard (neither — it is RPC), min relay fee,
`MAX_STANDARD_TX_WEIGHT`, `MAX_BLOCK_WEIGHT`. Add the source file for each.
