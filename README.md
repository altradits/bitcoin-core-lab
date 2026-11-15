# Bitcoin Core & Lightning Lab (`bitcoin-core-lab`)

[![CI](https://github.com/altradits/bitcoin-core-lab/actions/workflows/ci/badge.svg)](https://github.com/altradits/bitcoin-core-lab/actions/workflows/ci)
[![License: MIT](https://img.shields.io/badge/License-MIT-F7931A.svg)](./LICENSE)

A self-paced, offline-friendly curriculum for becoming a **Bitcoin Core / Lightning reviewer and
contributor**: from your first regtest node to reviewing consensus, P2P, mempool and wallet PRs and
contributing upstream. Built for **BitDevs Kisumu** and for anyone preparing to apply to
**Btrust** or similar developer programs.

## The rule: no shortcuts
You type every command and write every line of code that teaches a skill
([`CURRICULUM_CONVENTIONS.md`](./CURRICULUM_CONVENTIONS.md)):
- **Worksheets** (`NN-stage/exercises/`) say *what* to achieve and *which* RPC, file or function to use,
  with layered hints — never the finished command.
- **Checkers** (`check_*.sh`, `test_*.py`, Go tests) inspect your node, your files or your code and
  print PASS/FAIL with a reason — never the answer.
- **Solutions** (`NN-stage/solutions/`) are spoilers: open them after a checker passes or after three
  honest attempts.
- Your work goes in [`my-work/`](./my-work/README.md) (journals, answers, your programs).
- Nothing in this repo is a review comment or ACK to post in your name. Bitcoin Core's
  `doc/AI_POLICY.md` (master) and `CONTRIBUTING.md` apply to everything you publish.

## Start here
0. [`START_HERE.md`](./START_HERE.md) — what to install (pinned versions), `./lab.sh doctor`, and the stage map with time estimates.
1. [`CURRICULUM.md`](./CURRICULUM.md) — every competency (`C-…` IDs), the stage map, a weekly schedule and three mastery checkpoints.
2. [`00-start-small/`](./00-start-small/README.md) — your first node and first program, in micro-steps.
3. [`BTRUST_READINESS_TRACKER.md`](./BTRUST_READINESS_TRACKER.md) — the evidence log you fill as you go,
   and [`BTRUST_AND_BITDEVS_PLAYBOOK.md`](./BTRUST_AND_BITDEVS_PLAYBOOK.md) — verified program requirements.

## Stages

| # | Stage | You will be able to… |
|---|-------|----------------------|
| 00 | [Start small](./00-start-small/README.md) | run regtest, read UTXOs, write a 60-line Go program against your node |
| 01 | [Node foundations](./01-node-foundations/README.md) | write your own `bitcoin.conf` and start/stop procedure; coinbase maturity and subsidy |
| 02 | [Raw tx & mempool](./02-raw-tx-and-mempool/README.md) | decode a tx byte by byte; build/sign/broadcast raw txs; tell policy from consensus |
| 03 | [RBF & CPFP](./03-rbf-and-cpfp/README.md) | replace and fee-bump by hand with exact arithmetic; full-RBF |
| 04 | [Functional tests](./04-functional-test-framework/README.md) | write a two-node functional test and prove it catches a bug |
| 05 | [TRUC & package relay](./05-truc-package-relay-review/README.md) | submit TRUC packages, sibling eviction, ephemeral dust; write a concept review |
| 06 | [HTLCs](./06-lightning-htlc-state-machine/README.md) | assemble an HTLC by hand and spend both branches; compare with BOLT 3 |
| 07 | [PSBT, descriptors, miniscript](./07-psbt-descriptors-and-miniscript/README.md) | implement PSBT/descriptor pieces in Go; air-gapped PSBT flow by CLI |
| 08 | [Builder starter kit](./08-builder-starter-kit/README.md) | build a small Go tool on bitcoind JSON-RPC |
| 09 | [Bug dojo](./09-bug-dojo-and-pr-mastery/README.md) | fix real historical bugs; write a regression test that kills mutants |
| 10 | [Primitives from scratch](./10-protocol-primitives-from-scratch/README.md) | hashing, CompactSize, tx parsing, PoW/retarget, Merkle (CVE-2012-2459), bech32m, script numbers |
| 11 | [Regtest → signet → mainnet](./11-from-regtest-to-live-mainnet/README.md) | write node configs; sync signet; wallet backup/restore/watch-only drill |
| 12 | [Lightning readiness](./12-lightning-readiness-and-bitcoind-bridge/README.md) | channel state machine; `lnd.conf` against bitcoind; Polar channel lifecycle |
| 13 | [Core codebase, build, unit tests](./13-core-codebase-build-and-unit-tests/README.md) | navigate, build and test the C++; write a Boost unit test |
| 14 | [P2P & net_processing](./14-p2p-and-net-processing/README.md) | read `net`/`net_processing`; write a `P2PInterface` test |
| 15 | [Validation, chainstate, reorgs](./15-validation-chainstate-and-reorgs/README.md) | trace block validation; drive and test reorgs; assumeutxo |
| 16 | [Script, Taproot, libsecp256k1](./16-script-taproot-and-libsecp256k1/README.md) | interpreter, sighashes, taproot spends, Schnorr/MuSig2 concepts |
| 17 | [Fuzzing, sanitizers, debugging, CI](./17-fuzzing-sanitizers-debugging-and-ci/README.md) | write a fuzz target, use sanitizers and lldb, bisect, reproduce CI |
| 18 | [Cluster mempool, wallet, policy](./18-cluster-mempool-wallet-and-policy/README.md) | chunks and feerate diagrams; package RBF; coin selection |
| 19 | [Review & contribution practicum](./19-review-and-contribution-practicum/README.md) | blind-review real merged PRs, PR Review Club, your own contributions |

## `./lab.sh`
```
./lab.sh doctor                  # check installed tools and versions
./lab.sh stage <00..19>          # README, worksheets and checkers of a stage
./lab.sh check <00..19>          # run that stage's checkers
./lab.sh blank|solve <07|08|10|11|12>   # Go stages: fresh skeleton / reference (your file is backed up)
./lab.sh dojo break|check [1-6]|solve   # Stage 09
./lab.sh step <1..5>             # Stage 00 micro-steps (shows the worksheet section)
./lab.sh drill <1..8>            # from-source repetition drills
./lab.sh book | recall | bip <n> | bolt <n>   # offline library
./lab.sh journeys | pr-list | pr-audit <n>    # PR study material (blank review checklists)
./lab.sh health | rest           # 8 GB M1: check RAM, stop daemons
./lab.sh selftest                # check the lab itself (skeletons fail, solutions pass)
```

## Reference material
- [`offline-library/`](./offline-library/OFFLINE_INDEX.md) — from-memory workbooks, offline books, the whitepaper, blind-recall drills.
- [`pr-reviews/`](./pr-reviews/README.md) — review method, merged-PR review journeys, and auto-generated PR study files
  (read the known-issues list in that README first).
- [`BUILDING_BITCOIN_CORE_FROM_SOURCE.md`](./BUILDING_BITCOIN_CORE_FROM_SOURCE.md) (repetition drills: clone, build, test, review),
  [`FIRST_PRINCIPLES_WORKBOOK.md`](./FIRST_PRINCIPLES_WORKBOOK.md) (whitepaper ideas mapped to code),
  [`BITCOIN_CORE_SECURITY_NOTES.md`](./BITCOIN_CORE_SECURITY_NOTES.md) (past consensus bugs, how to read a PR),
  [`OFFLINE_30_DAY_CURRICULUM.md`](./OFFLINE_30_DAY_CURRICULUM.md) (days without internet).

## Environment
Tested with Bitcoin Core v29.0, Go 1.22+, Python 3.10+ and LND v0.20.0-beta (via Polar, Stage 12).
Written for an Apple M1 with 8 GB RAM (Linux works too): one `bitcoind` at a time, small `dbcache`,
limited `-j` when building. Bitcoin Core source at `~/bitcoin` (override with `BITCOIN_ROOT`), books
and specs at `~/bitcoin-references` (override with `BITCOIN_REFERENCES`). Stages teach current
`master` and note where the v29.x binary behaves differently. Regtest and signet only: no exercise
uses real money.

## Contributing
Found a mistake or want to add an exercise? See [`CONTRIBUTING.md`](./CONTRIBUTING.md) and
[`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md). Third-party material (books, BIPs, BOLTs, specs) is
linked, not copied: see [`LICENSES.md`](./LICENSES.md).

---

Maintained by Stanley Chege Thuita ([@altradits](https://github.com/altradits)), BitDevs Kisumu · MIT License
