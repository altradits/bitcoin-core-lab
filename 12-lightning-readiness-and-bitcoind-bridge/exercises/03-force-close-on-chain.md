# Stage 12 Worksheet 3: Find the Bitcoin Core in a force-close

**Output:** journal. **Checker:** self-check against the questions below.

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
