# Start here

This lab teaches you to build on and contribute to Bitcoin Core and LND.
Work through the stages in order. Each stage is short, runs on your own
machine, and ends with a check you can run to prove it works.

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

You also need about 20 GB of free disk space. A pruned node uses about
16 GB. See Stage 11 for the exact disk math.

Bitcoin Core install guides: `doc/build-osx.md` for Mac and
`doc/build-unix.md` for Linux, both in the
[bitcoin/bitcoin](https://github.com/bitcoin/bitcoin) repository.
The drill manual
[BUILDING_BITCOIN_CORE_FROM_SOURCE.md](./BUILDING_BITCOIN_CORE_FROM_SOURCE.md)
walks through the same steps with repetition drills.

## How the lab is organized

There are 13 stages, numbered 00 to 12. Each stage folder holds one
README and the scripts or code for that stage. Every stage README uses
the same template (see [docs/STAGE_TEMPLATE.md](./docs/STAGE_TEMPLATE.md)):

Goal, Why it matters, Prerequisites, Setup, Steps, Checkpoint,
Common errors and fixes, Going further, Contribution task, Sources.

Stages build on each other. Stage 01 starts your node and creates the
wallets that later stages reuse. Do not skip ahead unless a stage says
you can.

The helper script `./lab.sh` runs demos and checks. Run `./lab.sh help`
to list commands. It never touches mainnet.

## The five minute fast path

Run this to confirm your machine is ready:

```bash
git clone https://github.com/altradits/bitcoin-core-lab.git
cd bitcoin-core-lab
./lab.sh doctor
./lab.sh step 1
```

Expected result: `doctor` reports each tool as OK, and `step 1` shows
your node mining one regtest block. If `doctor` reports a missing tool,
install it and run `doctor` again. Then start Stage 00.

## Stage map

Times are honest estimates for a first pass. Double them if you do
every Going further exercise.

| Stage | Topic | Time | After this stage you can |
| :--- | :--- | :--- | :--- |
| [00](./00-start-small/README.md) | Start small: your first block, coins, and send | 1 hour | Mine a block, list coins, send coins on regtest |
| [01](./01-node-foundations/README.md) | Node basics: coinbase maturity and halvings | 2 hours | Explain why new coins wait 100 blocks |
| [02](./02-raw-tx-and-mempool/README.md) | Raw transactions, fees, and SegWit weight | 2 hours | Build and send a raw transaction by hand |
| [03](./03-rbf-and-cpfp/README.md) | Fee bumps: BIP125 RBF and CPFP | 3 hours | Replace a stuck transaction two ways |
| [04](./04-functional-test-framework/README.md) | Python functional tests | 3 hours | Run and write a two node framework test |
| [05](./05-truc-package-relay-review/README.md) | TRUC (v3) and package relay | 3 hours | Submit a 1 parent 1 child package |
| [06](./06-lightning-htlc-state-machine/README.md) | HTLC contracts on Bitcoin | 3 hours | Build a hash locked contract with a timeout refund |
| [07](./07-psbt-descriptors-and-miniscript/README.md) | Descriptors and offline signing (PSBT) | 3 hours | Sign with a watch only wallet plus an offline signer |
| [08](./08-builder-starter-kit/README.md) | Build an app on top of bitcoind | 4 hours | Serve invoices and timestamps over HTTP with Go |
| [09](./09-bug-dojo-and-pr-mastery/README.md) | Bug dojo: break and fix real bugs | 6 hours | Reproduce five historical bugs and write the fixes |
| [10](./10-protocol-primitives-from-scratch/README.md) | Protocol code from scratch in Go | 6 hours | Hash, serialize, and verify blocks without libraries |
| [11](./11-from-regtest-to-live-mainnet/README.md) | Run a pruned node on a small machine | 3 hours | Size and run a node that fits your disk and RAM |
| [12](./12-lightning-readiness-and-bitcoind-bridge/README.md) | Connect Lightning (LND) to your node | 4 hours | Open channels on a local Polar network |

Suggested order: 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12.
If you only want Lightning, you still need 00 through 06 first.

## After the stages

* Read the [30 day study plan](./OFFLINE_30_DAY_CURRICULUM.md) for a
  daily schedule that repeats the stages.
* Study real reviews in [pr-reviews/](./pr-reviews/) and write your own
  review of one open pull request.
* Practice recall with the [offline library](./offline-library/OFFLINE_INDEX.md)
  workbooks.
* Read the [grant and meetup guide](./BTRUST_AND_BITDEVS_PLAYBOOK.md)
  when you are ready to apply for funding or run a study group.

## Getting help

If a step fails, read the Common errors section of that stage first.
If the lab itself is wrong or unclear, open an issue on GitHub so a
maintainer can fix it. See [CONTRIBUTING.md](./CONTRIBUTING.md) for how
to report mistakes and propose new exercises.
