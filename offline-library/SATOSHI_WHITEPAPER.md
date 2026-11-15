# Whitepaper study guide: section map to Bitcoin Core code

Satoshi Nakamoto, *Bitcoin: A Peer-to-Peer Electronic Cash System*
(October 31, 2008).

Read the paper itself at https://bitcoin.org/bitcoin.pdf (9 pages).
This file does not reproduce it: the paper carries no explicit licence
grant, so the lab links to it instead of copying it. Short quotes
below are attributed excerpts for study. Everything else here is
original: a one paragraph summary of each section plus the Bitcoin
Core file that implements it.

## Abstract

Summary: electronic cash without a trusted third party, built from
digital signatures plus a peer to peer network that timestamps
transactions into proof of work.

> "We propose a solution to the double-spending problem using a
> peer-to-peer network."

## 1. Introduction

Summary: online payments depend on trusted mediators, which adds cost
and forces reversibility. The paper asks for payments based on
cryptographic proof instead of trust.

> "What is needed is an electronic payment system based on
> cryptographic proof instead of trust."

## 2. Transactions

Summary: a coin is a chain of signatures. The payee can verify
ownership but cannot detect double spending alone, so the network
must agree on one public history.

> "We define an electronic coin as a chain of digital signatures."

Bitcoin Core mapping:

* `CTransaction`, `CTxIn`, `CTxOut`, `COutPoint`:
  `src/primitives/transaction.h`
* Signature and script evaluation: `src/script/interpreter.cpp`
* UTXO database (`CCoinsViewCache`): `src/coins.h`

Lab: Stages 01 and 02.

## 3. Timestamp Server

Summary: hash items into timestamped blocks, each including the
previous hash, so history cannot be rewritten without redoing the work.

> "Each timestamp includes the previous timestamp in its hash,
> forming a chain."

Bitcoin Core mapping:

* `CBlockHeader` (`nVersion`, `hashPrevBlock`, `hashMerkleRoot`,
  `nTime`, `nBits`, `nNonce`): `src/primitives/block.h`

Lab: Stage 10.

## 4. Proof of Work

Summary: one CPU one vote replaces one IP one vote. Difficulty
retargets to hold block time constant as hardware changes.

> "Proof-of-work is essentially one-CPU-one-vote."

Bitcoin Core mapping:

* `CheckProofOfWork`, `GetNextWorkRequired` (2016 block retarget):
  `src/pow.cpp`

Lab: Stages 01 and 10.

## 5. Network

Summary: the six step loop (broadcast, collect, mine, broadcast,
validate, extend) plus the longest chain rule.

> "Nodes always consider the longest chain to be the correct one."

Bitcoin Core mapping:

* P2P messages (`inv`, `getdata`, `tx`, `block`, `headers`,
  `cmpctblock`): `src/net_processing.cpp`
* Chain validation, `ActivateBestChain`: `src/validation.cpp`

Lab: Stage 04.

## 6. Incentive

Summary: the block subsidy bootstraps the network; fees take over as
the subsidy ends at 21,000,000 BTC. The fee is implicit: inputs minus
outputs.

> "Once a predetermined number of coins have entered circulation,
> the incentive can transition entirely to transaction fees."

Bitcoin Core mapping:

* `GetBlockSubsidy`: `src/validation.cpp`
* `COINBASE_MATURITY = 100`: `src/consensus/consensus.h`
* `txfee_aux = nValueIn - value_out`: `src/consensus/tx_verify.cpp`

Lab: Stages 01 and 02.

## 7. Reclaiming Disk Space

Summary: spent transactions can be pruned once buried; the Merkle
root keeps the block hash intact.

Bitcoin Core mapping:

* `ComputeMerkleRoot`, `BlockMerkleRoot`:
  `src/consensus/merkle.cpp`

Lab: Stages 10 and 11.

## 8. Simplified Payment Verification

Summary: light clients keep 80 byte headers (about 4.2 MB per year
at the time) plus Merkle branches instead of full blocks.

Lab: Stage 11.

## 9. Combining and Splitting Value

Summary: transactions fan many inputs into at most two outputs
(payment plus change), which is why wallets manage change addresses.

> "Normally there will be either a single input ... and at most two
> outputs: one for the payment, and one returning the change, if
> any, back to the sender."

Lab: Stage 02.

## 10. Privacy

Summary: pseudonymous keys plus a fresh key pair per transaction
limit linkage, since all transactions are public.

Lab: Stage 07.

## 11 and 12. Calculation and Conclusion

Summary: the attacker catch up probability drops exponentially with
confirmations. The system works when honest nodes hold the majority
of CPU power.

> "We have proposed a system for electronic transactions without
> relying on trust."
