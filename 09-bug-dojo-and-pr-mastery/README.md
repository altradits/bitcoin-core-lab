# Stage 09: Bug dojo

You learn consensus and policy code by breaking it. Each mission loads
a vulnerable version of one function, you watch an exploit test fail,
you write the fix, and the test passes. The missions mirror real
Bitcoin Core history: two CVEs and three upstream pull requests.

## Goal

After this stage you can reproduce five historical Bitcoin Core bugs
in Go, write each fix, and map each fix to its upstream C++ code.

## Why it matters

Reviewers who have seen a bug class before catch it in review. The
2010 overflow bug (CVE-2010-5139) and the 2018 duplicate input bug
(CVE-2018-17144) are why `CheckTransaction` looks the way it does
today. The three pull request missions (BIP32 seed bounds, sigop
adjusted vsize, PSBT signature handling) show how small hardening
patches get reviewed and merged upstream.

## Prerequisites

* Go 1.22 or later.
* Stages 02 and 03 (fees, weight, RBF rules) so the mission briefings
  make sense.
* No node needed. The dojo is pure Go.

## Setup

```bash
go -C ./09-bug-dojo-and-pr-mastery test ./...
```

Expected output:

```text
ok  	github.com/altradits/bitcoin-core-lab/09-bug-dojo-and-pr-mastery	0.857s
```

The checked in code holds the solved state, so this passes before you
begin.

## Steps

### Step 1: Break all five missions

```bash
./lab.sh dojo break
./lab.sh dojo check
```

Expected output:

```text
Loaded BROKEN pre-PR code into 09-bug-dojo-and-pr-mastery/dojo_missions.go!
--- FAIL: TestMission1_ConsensusShield_CVE2010_And_CVE2018 (0.00s)
--- FAIL: TestMission2_PR35320_BIP32SeedLengthValidation (0.00s)
--- FAIL: TestMission3_PR32800_SigopAdjustedVsize (0.00s)
--- FAIL: TestMission4_BIP125_RBF_DoSProtection (0.00s)
--- FAIL: TestMission5_PR33014_PSBTInvalidSignatureHandling (0.00s)
FAIL
```

`dojo break` copies the vulnerable variant over `dojo_missions.go`.
Your job is to fix it back, one mission at a time.

### Step 2: Fix Mission 1 (consensus shield)

Open `dojo_missions.go` and find `CheckTransactionConsensus`. The
broken version sums outputs before checking them and never looks for
duplicate inputs. Write the fix:

1. Inside the output loop, reject `txout.Value < 0`
   (`bad-txns-vout-negative`) and `txout.Value > MAX_MONEY`
   (`bad-txns-vout-toolarge`) before adding to the running total.
2. After each addition, reject a total below 0 or above MAX_MONEY
   (`bad-txns-txouttotal-toolarge`). This catches the int64 overflow
   where two huge outputs sum to a negative number.
3. Track input outpoints in a map and reject repeats
   (`bad-txns-inputs-duplicate`).

Verify with:

```bash
./lab.sh dojo check 1
```

Expected output:

```text
--- PASS: TestMission1_ConsensusShield_CVE2010_And_CVE2018 (0.00s)
ok
```

Upstream reference: `CheckTransaction` in
`src/consensus/tx_check.cpp`.

### Step 3: Fix Mission 2 (BIP32 seed bounds)

Find `DeriveBIP32MasterKey`. BIP32 requires the seed to be 16 to 64
bytes (128 to 512 bits). The broken version accepts any length,
including empty seeds that derive brute forcible keys. Reject
`len(seed) < 16 || len(seed) > 64` before the HMAC call, then run
`./lab.sh dojo check 2`.

Upstream reference: `CExtKey::SetSeed` in `src/key.cpp`
(`bitcoin/bitcoin#35320`). Note: upstream uses `Assert`, a debug
abort, while this mission returns a Go error. Same bound, different
idiom.

### Step 4: Fix Mission 3 (sigop adjusted vsize)

Find `ComputeMempoolVsizes`. A tiny transaction full of signature
checks costs more CPU than its bytes suggest, so policy charges the
larger of weight and `sigOpCost * 20` weight units. Compute
`sigOpWeight`, take the max with `txWeight`, and divide by 4 rounding
up. Then run `./lab.sh dojo check 3`.

Upstream reference: `GetVirtualTransactionSize` in
`src/policy/policy.cpp` (`bitcoin/bitcoin#32800`).

### Step 5: Fix Mission 4 (RBF rules)

Find `ValidateBIP125Replacement`. A replacement must pay a strictly
higher feerate than the original (compare with cross multiplication,
no floats), must pay at least as much total fee (Rule 3), and must add
enough extra fee to cover its own relay bandwidth (Rule 4). Then run
`./lab.sh dojo check 4`.

Upstream reference: `PaysForRBF` in `src/policy/rbf.cpp`. You verified
Rule 4 live in Stage 03.

### Step 6: Fix Mission 5 (PSBT signatures)

Find `ProcessPSBTPartialSignatures`. A PSBT can arrive with a
corrupted pre existing signature. The fixed code validates every
existing signature (DER length 9 to 73 bytes, valid flag) and reports
which pubkey failed instead of crashing or silently dropping data.
Then run `./lab.sh dojo check 5`.

Upstream reference: `descriptorprocesspsbt` in
`src/rpc/rawtransaction.cpp` (`bitcoin/bitcoin#33014`).

### Step 7: Confirm everything passes

```bash
./lab.sh dojo check
```

Expected output:

```text
--- PASS: TestMission1_ConsensusShield_CVE2010_And_CVE2018 (0.00s)
--- PASS: TestMission2_PR35320_BIP32SeedLengthValidation (0.00s)
--- PASS: TestMission3_PR32800_SigopAdjustedVsize (0.00s)
--- PASS: TestMission4_BIP125_RBF_DoSProtection (0.00s)
--- PASS: TestMission5_PR33014_PSBTInvalidSignatureHandling (0.00s)
ok
```

If you get stuck on a mission, compare against
`solutions/dojo_missions_solved.go`, or restore everything with
`./lab.sh dojo solve` and start that mission over.

## Checkpoint

```bash
./lab.sh check 09
```

Expected output:

```text
PASS: stage 09. all five dojo missions pass.
```

The check runs the full dojo suite and requires all five missions to
pass. It does not break your code first. Run `./lab.sh dojo check`
by hand for the same result.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `CVE-2010-5139 VULNERABILITY: int64 output overflow was not caught` | Per output check missing or placed after the addition | Check each output before `nValueOut += txout.Value` |
| `expected bad-txns-txouttotal-toolarge` | Cumulative sum check missing | Check the running total inside the loop, not just at the end |
| `PR #35320 VULNERABILITY: accepted weak 8-byte seed` | Length guard missing | Reject `len(seed) < 16` first |
| `expected vsize_bip141=100 and vsize_adjusted=400` | Max with sigop weight missing | Take `max(txWeight, sigOpCost * 20)` before dividing |
| `BIP125 Rule #4 VULNERABILITY` | Relay floor missing | Require `additionalFee >= replacementVsize * relayPerVB` |
| My fixes vanished | You ran `dojo break` again | That overwrites your file. `dojo solve` restores the reference |

## Going further

1. Add a mutation test. Comment out one check in your fixed Mission
   1, run `dojo check 1`, and confirm it fails. Restore the check.
   Done when you have seen the failure.
2. Harden Mission 2 with a BIP32 test vector. Add a test that derives
   the master key for a known seed and compares against the published
   vector. Done when the new test passes.
3. Read the real CVE-2018-17144 patch. Find the duplicate input check
   in `src/consensus/tx_check.cpp` and compare it with your Go map.
   Done when you can point to both.

## Contribution task

Read the audit for one of the three dojo pull requests in
`pr-reviews/` (PR 32800, 33014, or 35320), then open the actual
upstream pull request on GitHub and read one reviewer thread the audit
does not quote. Write down what the reviewer asked and how the author
answered. Bring it to your study group or post it as a comment on the
audit issue if one exists.

## Sources

* `src/consensus/tx_check.cpp` (`CheckTransaction`): the consensus
  shield for Missions 1.
* `src/key.cpp` (`CExtKey::SetSeed`), `src/policy/policy.cpp`
  (`GetVirtualTransactionSize`), `src/rpc/rawtransaction.cpp`
  (`descriptorprocesspsbt`): Missions 2, 3, 5.
* `src/policy/rbf.cpp` (`PaysForRBF`): Mission 4.
* BIP32 (HD wallets), BIP125 (RBF): the standards behind Missions 2
  and 4.
* https://bitcoincore.org/en/2018/09/20/notice/: full disclosure of
  CVE-2018-17144 (timeline, affected versions, root cause).
