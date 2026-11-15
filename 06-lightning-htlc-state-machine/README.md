# Stage 06: HTLC contracts on Bitcoin

You build a Hash Time Locked Contract as a native SegWit (P2WSH)
output and verify both branches: instant claim with the preimage, and
refund after a 10 block timeout. You also verify both failure modes:
a wrong preimage and an early refund.

## Goal

After this stage you can write a two branch witness script, fund it,
and spend each branch with the correct witness stack.

## Why it matters

Lightning payments are HTLCs. A Hash Time Locked Contract pays the
receiver if they reveal a secret, or refunds the sender after a
timeout. BOLT 2 and BOLT 3 build multi hop payments from this exact
shape: `OP_SHA256` for the hash lock, `OP_CHECKSEQUENCEVERIFY`
(BIP112) for the relative timeout. This stage runs the same logic on
layer 1 so you trust it before you meet `lnd`.

## Prerequisites

* Stage 02 (raw transactions and SegWit witnesses).
* One coin of at least 5 BTC in `kisumu_miner`.
* `BITCOIN_ROOT` set to your Bitcoin Core checkout. The script imports
  the Python test framework for keys and transaction building.

## Setup

```bash
export BITCOIN_ROOT="$HOME/bitcoin"
bitcoin-cli -regtest -rpcwallet="kisumu_miner" getbalance
```

Expected output (any value above 5 works):

```text
50.00000000
```

If the balance is too low, run `./lab.sh step 1` to mine more blocks.

## Steps

### Step 1: Read the contract

The script uses fixed keys and a fixed secret, so every value below is
reproducible. Secret preimage `R`:

```text
kisumu_lightning_htlc_secret_001
```

Payment hash `H = SHA256(R)`:

```bash
python3 -c "import hashlib; print(hashlib.sha256(b'kisumu_lightning_htlc_secret_001').hexdigest())"
```

Expected output:

```text
742af20ce270fb0e8ae2c5be398a44554cbddcb1bd005ea7bbadef3c522e7afa
```

Witness script (IF branch: merchant claims with the preimage; ELSE
branch: sender refunds after 10 blocks):

```text
OP_IF
    OP_SHA256 742af20c...e7afa OP_EQUALVERIFY
    020d4804...fe507 OP_CHECKSIG
OP_ELSE
    10 OP_CHECKSEQUENCEVERIFY OP_DROP
    022d7d6a...b637d OP_CHECKSIG
OP_ENDIF
```

Full script hex:

```text
63a820742af20ce270fb0e8ae2c5be398a44554cbddcb1bd005ea7bbadef3c522e7afa8821020d48049735e22172d677161edb6b5ef3ddf39d82949f011f22260250165fe507ac675ab27521022d7d6adbdca821933ac3b0a6baedeb9492a1f822dcfde032c580831c185b637dac68
```

It pays to this P2WSH address (verify with `decodescript`):

```text
bcrt1q00umt9mrdel5ufvwnnh7my5y4pmkgufnzdm4vvdupetrk0pna8jql56sqa
```

### Step 2: Fund the contract and verify both branches

```bash
python3 ./06-lightning-htlc-state-machine/verify_htlc.py
```

Expected output (txids differ; verdicts do not):

```text
Wrong preimage: allowed=False reject-reason='mandatory-script-verify-flag-failed (Script failed an OP_EQUALVERIFY operation)'
Preimage Claim TXID: fee5357555629d395713b6a87685d92cf41c90f18294b480d34e488240df67ca
Early refund: allowed=False reject-reason='non-BIP68-final'
CSV Timeout Refund TXID: 9d631f524e48a585ec15dfa5c8cbcf62014135671e717b34b951ca2ca91aa30a
PASS: HTLC preimage claim and CSV refund both verified.
```

The script funds two 1 BTC HTLC outputs, then runs four checks:

1. Wrong preimage. A claim with `wrong_secret_preimage_0000000000`
   fails `OP_EQUALVERIFY` inside `OP_IF`. The signature is valid;
   the hash is not.
2. Valid claim. The merchant witness `[sig, R, 0x01, script]`
   settles at once. `0x01` selects the IF branch.
3. Early refund. A refund with `nSequence = 10` at 1 confirmation
   fails with `non-BIP68-final`. The witness `[sig, "", script]`
   selects ELSE (the empty push satisfies `MINIMALIF`).
4. Matured refund. After 9 more blocks (10 confirmations) the same
   transaction confirms.

### Step 3: Read the enforcement code

Relative lock enforcement has two layers. Consensus checks the script
flag in `EvalScript` (`src/script/interpreter.cpp`,
`OP_CHECKSEQUENCEVERIFY` case), and mempool plus block validation
check the input age in `SequenceLocks`
(`src/consensus/tx_verify.cpp`), which produces `non-BIP68-final`.
Find both with:

```bash
grep -n "OP_CHECKSEQUENCEVERIFY" ~/bitcoin/src/script/interpreter.cpp | head -3
grep -rn "non-BIP68-final" ~/bitcoin/src/consensus/tx_verify.cpp | head -3
```

Expected output (line numbers may differ by release):

```text
560:                case OP_CHECKSEQUENCEVERIFY:
```

plus the `non-BIP68-final` return in `tx_verify.cpp`. The script flag
and the age check must both pass.

## Checkpoint

```bash
./lab.sh check 06
```

Expected output:

```text
PASS: stage 06. HTLC preimage claim and CSV refund both verified.
```

The check runs the Step 2 script and requires its final PASS line.
You can also rerun the script by hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `ModuleNotFoundError: test_framework` | `BITCOIN_ROOT` is unset or wrong | Export it as in Setup; the script reads `$BITCOIN_ROOT/test/functional` |
| `list index out of range` on `listunspent` | No coin of at least 5 BTC | Mine more (`./lab.sh step 1`), then retry |
| `non-BIP68-final` on the valid claim | You edited the claim sequence | Claims use final sequence, not 10; rerun the script unchanged |
| `mandatory-script-verify-flag-failed` on the valid claim | Wrong preimage bytes | The preimage is exactly `kisumu_lightning_htlc_secret_001` |

## Going further

1. Change the timeout. Set `csv_delay = 3` in the script, adjust the
   mining count, and confirm the refund verifies. Done when PASS
   prints with the new delay.
2. Try an absolute timeout. Replace the ELSE branch with
   `OP_CHECKLOCKTIMEVERIFY` (BIP65) and a fixed locktime. Done when
   the early spend fails and the matured spend passes.
3. Map this to Lightning. Read BOLT 3, section on the HTLC output,
   and find the `OP_IF` revocation branch. Done when you can say how
   it differs from this contract (revocation key instead of sender
   key).

## Contribution task

Run the upstream script test suite and confirm it passes:

```bash
./build/bin/test_bitcoin --run_test=script_tests
```

Run from your `bitcoin` checkout (build it first if needed). If it
fails, open a lab bug issue with the output. Do not file upstream
until a maintainer confirms.

## Sources

* BIP68 (relative locktime with `nSequence`), BIP112
  (`OP_CHECKSEQUENCEVERIFY`), BIP65 (`OP_CHECKLOCKTIMEVERIFY`).
* `src/script/interpreter.cpp` (`EvalScript`): script execution.
* `src/consensus/tx_verify.cpp` (`SequenceLocks`): `non-BIP68-final`.
* BOLT 2 and BOLT 3: HTLCs in Lightning channels.
