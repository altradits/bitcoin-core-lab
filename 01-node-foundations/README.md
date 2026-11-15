# Stage 01: Node Foundations — your own `bitcoin.conf`, start/stop, coinbase rules and the UTXO set

> Source checked: Bitcoin Core `v29.0` (`git -C ~/bitcoin log -1 --oneline` →
> `f490f5562d`). Where `master` differs it is noted.

**No-Shortcuts Rule.** You write the config file, the start/stop script, and every RPC call.
Worksheets give goals and layered hints, never the finished command. Checkers inspect your files
and your node and print PASS/FAIL. Reference answers are in [`solutions/`](./solutions/) — open
them only after a check passes or after **3 honest attempts**. Record every command you type in
`my-work/01-node-foundations/journal.md`.

The old automation script (`verify_coinbase_maturity.sh`) now lives in
[`solutions/`](./solutions/verify_coinbase_maturity.sh) as a reference only.

---

## Objectives

| ID | You can... |
|----|------------|
| C-CONS-1 | state and test the coinbase rules: maturity (100), subsidy schedule and halving, coinbase value ≤ subsidy + fees, BIP34 height; compute the UTXO-set total by hand |
| C-VAL-5 (intro) | explain what a datadir holds (blocks, chainstate, indexes, wallets, `debug.log`, `.cookie`) and what happens on clean vs unclean shutdown |
| C-TX-1 (intro) | read a coinbase input (null prevout, scriptSig) and decode a little-endian script number |
| C-COMMS-1 | explain each config option in your own words (comment lines in your `bitcoin.conf`) |

## Prerequisites
Stage 00 done (you can create wallets, mine, send). `bitcoind -version` prints v29.0.

---

## Theory

### 1. The datadir and the config file
`bitcoind` keeps everything in one data directory. On macOS the default is
`~/Library/Application Support/Bitcoin/` (`doc/files.md`). Regtest data goes into a `regtest/`
sub-folder: `blocks/`, `chainstate/` (the UTXO set, LevelDB), `indexes/` (e.g. `txindex`),
`wallets/`, `debug.log`, and `.cookie` while the node runs.
The config file is `bitcoin.conf` in the datadir (`doc/bitcoin-conf.md`). It has a default section
and per-network sections `[main] [test] [testnet4] [signet] [regtest]`. Some options are
**network-only** (`-port -rpcport -bind -rpcbind -addnode -connect -wallet -walletdir`; registered
with `ArgsManager::NETWORK_ONLY` in `src/init.cpp`, `src/wallet/init.cpp`). Putting them in the
default section while running regtest is an init error (search `init.cpp` for `only applied on`).

### 2. RPC authentication
No credentials configured → `bitcoind` writes a random cookie (`.cookie`) at start-up and deletes
it at shutdown; `bitcoin-cli` reads it. Or use `-rpcauth` (salted HMAC-SHA256;
`share/rpcauth/rpcauth.py`). Never store `rpcpassword=` in plain text on a machine you care about.

### 3. The UTXO model
State = the set of unspent outputs (`chainstate/`). A transaction consumes outputs (inputs refer to
`txid:vout`) and creates outputs. Validity of spending depends only on the UTXO being present and
the script being satisfied — there are no accounts. Every full node holds the same UTXO set at the
same block. `gettxoutsetinfo` summarises it (count, total amount, a hash of the set).

### 4. Coinbase rules (consensus, `C-CONS-1`)
| Rule | Where |
|------|-------|
| exactly one input with a null prevout; scriptSig length 2..100 bytes | `CheckTransaction`, `src/consensus/tx_check.cpp` (`bad-cb-length`) |
| scriptSig starts with the block height (BIP34) | `ContextualCheckBlock`, `src/validation.cpp` (`bad-cb-height`) |
| outputs ≤ subsidy + fees | `ConnectBlock`, `src/validation.cpp` (`bad-cb-amount`) |
| spendable only after `COINBASE_MATURITY = 100` | `Consensus::CheckTxInputs`, `src/consensus/tx_verify.cpp` (`bad-txns-premature-spend-of-coinbase`) |
| subsidy = 50 BTC >> (height / interval) | `GetBlockSubsidy`, `src/validation.cpp`; interval 210,000 on mainnet, 150 on regtest (`src/kernel/chainparams.cpp`) |
| witness commitment in an `OP_RETURN` coinbase output (BIP141) | `GetWitnessCommitmentIndex`, `src/consensus/validation.h` |

`COINBASE_MATURITY` is declared as `static const int COINBASE_MATURITY = 100;` in
`src/consensus/consensus.h`.

**A subtle off-by-one you will measure yourself (Worksheet 3):** consensus checks a spend at
`nSpendHeight` = the height of the block the spend would be mined in, so the *mempool* accepts the
spend one block before the *wallet* (`GetTxBlocksToMaturity` in `src/wallet/wallet.cpp` uses
`COINBASE_MATURITY + 1`) reports the coins as `trusted`. Earlier versions of this lab's README
mixed the two up; your experiment settles it.

**Why maturity exists:** a coinbase belongs to one specific block. If that block is reorganised
away, the coinbase disappears entirely (it cannot be re-mined into another block, unlike a normal
transaction that goes back to the mempool). The 100-block wait makes such reorgs unrealistic before
the coins can move.

### 5. The genesis output is not spendable
`ConnectBlock` has a special case for the genesis block that skips adding its transactions to the
UTXO set (search `validation.cpp` for "Special case for the genesis block"). This is why the
UTXO-set total starts at block 1.

---

## Exercises (in order)

| # | Worksheet | Your output | Checker |
|---|-----------|-------------|---------|
| 1 | [`exercises/01-write-your-bitcoin-conf.md`](./exercises/01-write-your-bitcoin-conf.md) | `my-work/01-node-foundations/bitcoin.conf` | `./01-node-foundations/check_conf.sh` |
| 2 | [`exercises/02-start-stop-procedure.md`](./exercises/02-start-stop-procedure.md) | `my-work/01-node-foundations/node.sh` | `./01-node-foundations/check_node_procedure.sh [--cycle]` |
| 3 | [`exercises/03-coinbase-maturity-and-subsidy.md`](./exercises/03-coinbase-maturity-and-subsidy.md) | `answers.env`, wallet `maturity_lab` | `./01-node-foundations/check_coinbase.sh` |
| 4 | [`exercises/04-coinbase-anatomy.md`](./exercises/04-coinbase-anatomy.md) | `answers.env` | `./01-node-foundations/check_coinbase.sh` |

Copy [`exercises/answers.env.template`](./exercises/answers.env.template) to
`my-work/01-node-foundations/answers.env`. From this stage on, export `BTC_CLI` to point at
your own node (Worksheet 1, Task 4), and start/stop it only with your `node.sh`.

---

## Checkpoint

```bash
./lab.sh check 01
```

Runs: ./check_conf.sh, ./check_node_procedure.sh, ./check_coinbase.sh. Each prints PASS/FAIL with a reason, never the answer. Start your own regtest node first; the checkers read its state and your `answers.env`.
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_01=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).
1. Name four options that must go in the `[regtest]` section, and what happens if one is in the top section.
2. What does the `.cookie` file contain, and when does it exist?
3. Regtest block 300: what is its subsidy in satoshis, and why?
4. A coinbase is mined at height 500. At which tip does the mempool first accept a spend of it? At which tip does the wallet call it `trusted`?
5. Why is the genesis block's 50 BTC not part of the UTXO set?
6. Decode the BIP34 height pushed by `03a0bb0d`.
7. Which consensus rule stops a miner paying itself more than subsidy + fees, and what is its reject reason?
8. Why is the subsidy computed with a right shift, and why is there a special case for 64 or more halvings?
9. What does `-txindex` add, and which RPC needs it?

## Review lens
When reviewing a PR that touches node start-up, config parsing, or coinbase/subsidy logic:
- **Config/args:** `src/common/args.cpp` (`ArgsManager`), `src/init.cpp` (`AddArg`, network-only
  checks), `doc/bitcoin-conf.md`. Ask: does a new option need `NETWORK_ONLY`? Is it `SENSITIVE`
  (must not be logged)? Is the default documented in the help string? Is there a functional test
  (`test/functional/feature_config_args.py`)?
- **Coinbase/subsidy:** `GetBlockSubsidy`, `ConnectBlock` (`bad-cb-amount`),
  `ContextualCheckBlock` (`bad-cb-height`), `Consensus::CheckTxInputs` (maturity). Invariant: the
  money supply never exceeds the schedule (`MAX_MONEY` in `src/consensus/amount.h` is a sanity
  bound, not the schedule). Tests to read: `test/functional/mempool_spend_coinbase.py`,
  `feature_block.py` (search `bad-cb-amount`), `src/test/validation_tests.cpp` (subsidy tests).
- **Shutdown safety:** anything that changes flushing (`FlushStateToDisk`) or `-persistmempool`
  needs testing with a clean stop *and* an unclean one.

## Proof-of-work output
- Your commented `bitcoin.conf` and `node.sh` (publish them as a gist if you like; they contain no secrets when you use cookie auth).
- A short write-up in your own words: "The coinbase maturity off-by-one between wallet and consensus, measured on regtest" with your journal numbers.

## Next
Stage 02 ([`../02-raw-tx-and-mempool/README.md`](../02-raw-tx-and-mempool/README.md)).
