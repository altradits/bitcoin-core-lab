# Start here

This lab teaches you to build on and contribute to Bitcoin Core and LND.
Work through the stages in the order [CURRICULUM.md](./CURRICULUM.md) gives. Each stage runs on
your own machine and ends with checkers that prove your work.

The rule: no shortcuts. You type every command and write every line of code that teaches a
skill ([CURRICULUM_CONVENTIONS.md](./CURRICULUM_CONVENTIONS.md)). Worksheets say what to achieve,
checkers tell you PASS or FAIL with a reason, and `solutions/` folders are spoilers you open only
after a checker passes or after three honest attempts.

Rule 0: use regtest or signet only. Never use real money (mainnet) for
any exercise in this lab.

## Who this lab is for

You are a beginner to intermediate developer. You can write code in at
least one language and use a terminal. You want to make open source
contributions to Bitcoin Core or LND. You work on a Mac (Apple Silicon,
8 GB RAM) or Linux, sometimes without internet.

You do not need to know Bitcoin first. Stage 00 assumes nothing.

## What you need

Install these before Stage 01. Stage 00 needs only Bitcoin Core and Go.

| Tool | Pinned version | Check with |
| :--- | :--- | :--- |
| Bitcoin Core | v29.0 | `bitcoind --version` |
| Go | 1.22 or later | `go version` |
| Python | 3.10 or later | `python3 --version` |
| git | any recent | `git --version` |
| LND (Stage 12 only) | v0.20.0-beta via Polar | `./lab.sh polar` |

You also need disk space: a few GB for regtest, signet and a Bitcoin Core
build, and more for a pruned mainnet node (about 5.5 GB of block files
plus the UTXO set, which grows). Stage 11 has you measure it on your own
node.

Bitcoin Core install guides: `doc/build-osx.md` for Mac and
`doc/build-unix.md` for Linux, both in the
[bitcoin/bitcoin](https://github.com/bitcoin/bitcoin) repository.
The drill manual
[BUILDING_BITCOIN_CORE_FROM_SOURCE.md](./BUILDING_BITCOIN_CORE_FROM_SOURCE.md)
walks through the same steps with repetition drills.

## How the lab is organized

There are 20 stages, numbered 00 to 19. Each stage folder holds a README, worksheets in
`exercises/`, checkers (`check_*.sh`, Go tests or Python tests) and spoilers in `solutions/`.
Every stage README follows [docs/STAGE_TEMPLATE.md](./docs/STAGE_TEMPLATE.md). Your own
answers, journals and programs go in [my-work/](./my-work/README.md), which git ignores so you
choose what to publish.

`./lab.sh` shows stages and runs checkers; it never does the exercise for you. Run
`./lab.sh help` to list commands. It never touches mainnet.

## The five minute fast path

Run this to confirm your machine is ready:

```bash
git clone https://github.com/altradits/bitcoin-core-lab.git
cd bitcoin-core-lab
./lab.sh doctor
./lab.sh step 1
```

Expected result: `doctor` reports each tool as OK, and `step 1` shows
the first Stage 00 micro-step for you to do yourself. If `doctor` reports a missing tool,
install it and run `doctor` again. Then start Stage 00.

## Stage map

Hours are honest estimates for a first pass on an 8 GB machine, including journaling
(from [CURRICULUM.md](./CURRICULUM.md), which also has the week-by-week schedule).

| Stage | Topic | Time |
| :--- | :--- | :--- |
| [00](./00-start-small/README.md) | Start small: first node, UTXOs, a small Go program | 4 hours |
| [01](./01-node-foundations/README.md) | Your own bitcoin.conf; coinbase maturity and subsidy | 6 hours |
| [02](./02-raw-tx-and-mempool/README.md) | Raw transactions by hand; policy vs consensus | 10 hours |
| [03](./03-rbf-and-cpfp/README.md) | Fee bumps: RBF and CPFP with exact arithmetic | 8 hours |
| [04](./04-functional-test-framework/README.md) | Write a two node functional test that catches a bug | 12 hours |
| [05](./05-truc-package-relay-review/README.md) | TRUC (v3), package relay, ephemeral dust; a concept review | 10 hours |
| [06](./06-lightning-htlc-state-machine/README.md) | Assemble an HTLC and spend both branches | 8 hours |
| [07](./07-psbt-descriptors-and-miniscript/README.md) | PSBT, descriptors, miniscript in Go; offline signing | 10 hours |
| [08](./08-builder-starter-kit/README.md) | Build a Go tool on bitcoind JSON-RPC | 10 hours |
| [09](./09-bug-dojo-and-pr-mastery/README.md) | Fix historical bugs; write a regression test | 12 hours |
| [10](./10-protocol-primitives-from-scratch/README.md) | Hashing, serialization, PoW, Merkle, bech32m in Go | 14 hours |
| [11](./11-from-regtest-to-live-mainnet/README.md) | Node configs, signet sync, wallet backup drill | 6 hours |
| [12](./12-lightning-readiness-and-bitcoind-bridge/README.md) | LND against bitcoind; Polar channel lifecycle | 12 hours |
| [13](./13-core-codebase-build-and-unit-tests/README.md) | Build Bitcoin Core; write a unit test | 16 hours |
| [14](./14-p2p-and-net-processing/README.md) | P2P and net_processing; a P2PInterface test | 18 hours |
| [15](./15-validation-chainstate-and-reorgs/README.md) | Block validation, reorgs, assumeutxo | 18 hours |
| [16](./16-script-taproot-and-libsecp256k1/README.md) | Interpreter, sighashes, Taproot, Schnorr | 18 hours |
| [17](./17-fuzzing-sanitizers-debugging-and-ci/README.md) | Fuzz targets, sanitizers, lldb, bisect, CI | 16 hours |
| [18](./18-cluster-mempool-wallet-and-policy/README.md) | Cluster mempool, package RBF, coin selection | 18 hours |
| [19](./19-review-and-contribution-practicum/README.md) | Review real PRs; your own contributions | 40+ hours (ongoing) |

Stage 04 needs a Bitcoin Core build, which Stage 13 teaches; CURRICULUM.md says when to do it.
If you only want Lightning, you still need 00 through 06 first.

## After the stages

* Use the [30 offline study days](./OFFLINE_30_DAY_CURRICULUM.md) on
  days without internet.
* Study real reviews in [pr-reviews/](./pr-reviews/README.md) and log your
  evidence in [BTRUST_READINESS_TRACKER.md](./BTRUST_READINESS_TRACKER.md).
* Practice recall with the [offline library](./offline-library/OFFLINE_INDEX.md)
  workbooks.
* Read the [grant and meetup guide](./BTRUST_AND_BITDEVS_PLAYBOOK.md)
  when you are ready to apply for funding or run a study group.

## Getting help

If a step fails, read the Common errors section of that stage first.
If the lab itself is wrong or unclear, open an issue on GitHub so a
maintainer can fix it. See [CONTRIBUTING.md](./CONTRIBUTING.md) for how
to report mistakes and propose new exercises.
