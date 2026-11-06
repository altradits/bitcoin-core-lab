# Bitcoin Core and Lightning Lab

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

A hands on lab for learning to contribute to Bitcoin Core and LND.
You run a node on regtest, build transactions by hand, write tests,
review real pull requests, and connect a Lightning node. No real money
is used anywhere. Regtest and signet only.

New here? Read [Start here](./START_HERE.md). It lists what to install,
how much time each stage takes, and where to begin.

## Pinned versions

The lab is tested with these versions. Newer versions may work, but
these are the ones the steps and outputs match.

| Tool | Version |
| :--- | :--- |
| Bitcoin Core | v29.0 |
| Go | 1.22 or later |
| Python | 3.10 or later |
| LND (Stage 12, via Polar) | v0.20.0-beta |

## Stages

Work through the stages in order. Each stage README follows the same
template: goal, setup, numbered steps with expected output, a
checkpoint, common errors, and one small contribution task.

| Stage | Topic | Time |
| :--- | :--- | :--- |
| [00](./00-start-small/README.md) | Start small: first block, coins, and send | 1 hour |
| [01](./01-node-foundations/README.md) | Node basics: coinbase maturity and halvings | 2 hours |
| [02](./02-raw-tx-and-mempool/README.md) | Raw transactions, fees, and SegWit weight | 2 hours |
| [03](./03-rbf-and-cpfp/README.md) | Fee bumps: BIP125 RBF and CPFP | 3 hours |
| [04](./04-functional-test-framework/README.md) | Python functional tests | 3 hours |
| [05](./05-truc-package-relay-review/README.md) | TRUC (v3) and package relay | 3 hours |
| [06](./06-lightning-htlc-state-machine/README.md) | HTLC contracts on Bitcoin | 3 hours |
| [07](./07-psbt-descriptors-and-miniscript/README.md) | Descriptors and offline signing (PSBT) | 3 hours |
| [08](./08-builder-starter-kit/README.md) | Build an app on top of bitcoind | 4 hours |
| [09](./09-bug-dojo-and-pr-mastery/README.md) | Bug dojo: break and fix real bugs | 6 hours |
| [10](./10-protocol-primitives-from-scratch/README.md) | Protocol code from scratch in Go | 6 hours |
| [11](./11-from-regtest-to-live-mainnet/README.md) | Run a pruned node on a small machine | 3 hours |
| [12](./12-lightning-readiness-and-bitcoind-bridge/README.md) | Connect Lightning (LND) to your node | 4 hours |

## Guides and references

| Guide | What it covers |
| :--- | :--- |
| [BUILDING_BITCOIN_CORE_FROM_SOURCE.md](./BUILDING_BITCOIN_CORE_FROM_SOURCE.md) | Repetition drills: clone, build, test, review |
| [OFFLINE_30_DAY_CURRICULUM.md](./OFFLINE_30_DAY_CURRICULUM.md) | A 30 day study plan for offline work |
| [FIRST_PRINCIPLES_WORKBOOK.md](./FIRST_PRINCIPLES_WORKBOOK.md) | Whitepaper ideas mapped to C++ code and drills |
| [BITCOIN_CORE_SECURITY_NOTES.md](./BITCOIN_CORE_SECURITY_NOTES.md) | Past consensus bugs and how to audit a pull request |
| [BTRUST_AND_BITDEVS_PLAYBOOK.md](./BTRUST_AND_BITDEVS_PLAYBOOK.md) | Grants and running a local study group |
| [offline-library/](./offline-library/OFFLINE_INDEX.md) | Workbooks and recall drills for offline study |
| [pr-reviews/](./pr-reviews/) | Audits and review journeys of real upstream pull requests |

## Helper script

`./lab.sh` runs demos and checks for the stages. It assumes a
`bitcoind -regtest` node on this machine. Run `./lab.sh help` for the
full command list.

```bash
./lab.sh doctor     # check installed tools and versions
./lab.sh check 01   # run the automated checkpoint for a stage
```

## Layout

Each stage folder holds one README plus its scripts or Go module:

```text
00-start-small/          first block, coins, send, tiny Go program
01-node-foundations/     coinbase maturity script
...
09-bug-dojo-and-pr-mastery/  Go break and fix exercises
offline-library/         study workbooks and recall drills
pr-reviews/              upstream pull request audits
```

## Contributing

Found a mistake? See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to
report it. One line commit messages, no signing key needed.

## License

MIT. See [LICENSE](./LICENSE). Outside sources (books, whitepaper,
specs) are linked, not copied. See [LICENSES.md](./LICENSES.md).
