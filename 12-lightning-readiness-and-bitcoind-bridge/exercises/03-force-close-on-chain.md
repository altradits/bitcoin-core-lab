# Stage 12 Worksheet 3: Find the Bitcoin Core in a force-close

**Output:** journal and five answers. **Checker:** `./check_force_close.sh`. It inspects the transactions
on Polar's backend `bitcoind` (set `POLAR_CLI` if your network's RPC port or credentials differ; Polar shows
them under the node's *Connect* tab).

Put in `my-work/12-lightning-readiness-and-bitcoind-bridge/answers.env`: `COMMITMENT_TXID`,
`COMMITMENT_VERSION`, `IS_TRUC` (yes/no), `CSV_DELAY` (from `lncli pendingchannels`) and `SWEEP_TXID`
(the transaction that spends your `to_local` output once the delay has passed).

1. In Polar, open a new channel, make one payment, then **force-close** it from the payer side.
2. Find the commitment transaction on the backend `bitcoind`. Decode it. Label every output:
   `to_local`, `to_remote`, anchors (if any), HTLCs (if any). Compare the witness scripts with BOLT 3
   (Stage 06 Worksheet 3).
3. What is the commitment tx's `version` and feerate? Is it a TRUC (v3) transaction? Why / why not
   for your lnd version and channel type?
4. Mine blocks step by step. When does the `to_local` output become spendable? Match the number
   to the channel's `csv_delay` from `lncli pendingchannels`.
5. Which Bitcoin Core policy features from Stages 03, 05 and 18 would matter if the mempool were
   full at this moment? Write one paragraph in your own words.
