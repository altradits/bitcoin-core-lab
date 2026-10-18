# Bitcoin: A Peer-to-Peer Electronic Cash System

**Satoshi Nakamoto**  
*satoshin@gmx.com — www.bitcoin.org (October 31, 2008)*  
*(Local PDF Copy: `/Users/mac/bitcoin-references/bitcoin.pdf`)*

---

## Abstract
A purely peer-to-peer version of electronic cash would allow online payments to be sent directly from one party to another without going through a financial institution. Digital signatures provide part of the solution, but the main benefits are lost if a trusted third party is still required to prevent double-spending. We propose a solution to the double-spending problem using a peer-to-peer network. The network timestamps transactions by hashing them into an ongoing chain of hash-based proof-of-work, forming a record that cannot be changed without redoing the proof-of-work. The longest chain not only serves as proof of the sequence of events witnessed, but proof that it came from the largest pool of CPU power. As long as a majority of CPU power is controlled by nodes that are not cooperating to attack the network, they'll generate the longest chain and outpace attackers. The network itself requires minimal structure. Messages are broadcast on a best effort basis, and nodes can leave and rejoin the network at will, accepting the longest proof-of-work chain as proof of what happened while they were gone.

---

## 1. Introduction
Commerce on the Internet has come to rely almost exclusively on financial institutions serving as trusted third parties to process electronic payments. While the system works well enough for most transactions, it still suffers from the inherent weaknesses of the trust based model. Completely non-reversible transactions are not really possible, since financial institutions cannot avoid mediating disputes. The cost of mediation increases transaction costs, limiting the minimum practical transaction size and cutting off the possibility for small casual transactions, and there is a broader cost in the loss of ability to make non-reversible payments for non-reversible services. With the possibility of reversal, the need for trust spreads. Merchants must be wary of their customers, hassling them for more information than they would otherwise need. A certain percentage of fraud is accepted as unavoidable. These costs and payment uncertainties can be avoided in person by using physical currency, but no mechanism exists to make payments over a communications channel without a trusted party.

What is needed is an electronic payment system based on cryptographic proof instead of trust, allowing any two willing parties to transact directly with each other without the need for a trusted third party. Transactions that are computationally impractical to reverse would protect sellers from fraud, and routine escrow mechanisms could easily be implemented to protect buyers. In this paper, we propose a solution to the double-spending problem using a peer-to-peer distributed timestamp server to generate computational proof of the chronological order of transactions. The system is secure as long as honest nodes collectively control more CPU power than any cooperating group of attacker nodes.

---

## 2. Transactions
We define an electronic coin as a chain of digital signatures. Each owner transfers the coin to the next by digitally signing a hash of the previous transaction and the public key of the next owner and adding these to the end of the coin. A payee can verify the signatures to verify the chain of ownership.

The problem of course is the payee can't verify that one of the owners did not double-spend the coin. A common solution is to introduce a trusted central authority, or mint, that checks every transaction for double spending. After each transaction, the coin must be returned to the mint to issue a new coin, and only coins issued directly from the mint are trusted not to be double-spent. The problem with this solution is that the fate of the entire money system depends on the company running the mint, with every transaction having to go through them, just like a bank.

We need a way for the payee to know that the previous owners did not sign any earlier transactions. For our purposes, the earliest transaction is the one that counts, so we don't care about later attempts to double-spend. The only way to confirm the absence of a transaction is to be aware of all transactions. In the mint based model, the mint was aware of all transactions and decided which arrived first. To accomplish this without a trusted party, transactions must be publicly announced, and we need a system for participants to agree on a single history of the order in which they were received. The payee needs proof that at the time of each transaction, the majority of nodes agreed it was the first received.

> **Bitcoin Core C++ Mapping:**
> - `CTransaction`, `CTxIn`, `CTxOut`, `COutPoint` -> [`/Users/mac/bitcoin/src/primitives/transaction.h`](file:///Users/mac/bitcoin/src/primitives/transaction.h)
> - Signature & Script evaluation -> [`/Users/mac/bitcoin/src/script/interpreter.cpp`](file:///Users/mac/bitcoin/src/script/interpreter.cpp)
> - UTXO database (`CCoinsViewCache`) -> [`/Users/mac/bitcoin/src/coins.h`](file:///Users/mac/bitcoin/src/coins.h)

---

## 3. Timestamp Server
The solution we propose begins with a timestamp server. A timestamp server works by taking a hash of a block of items to be timestamped and widely publishing the hash, such as in a newspaper or Usenet post. The timestamp proves that the data must have existed at the time, obviously, in order to get into the hash. Each timestamp includes the previous timestamp in its hash, forming a chain, with each additional timestamp reinforcing the ones before it.

> **Bitcoin Core C++ Mapping:**
> - `CBlockHeader` (`nVersion`, `hashPrevBlock`, `hashMerkleRoot`, `nTime`, `nBits`, `nNonce`) -> [`/Users/mac/bitcoin/src/primitives/block.h`](file:///Users/mac/bitcoin/src/primitives/block.h)

---

## 4. Proof-of-Work
To implement a distributed timestamp server on a peer-to-peer basis, we will need to use a proof-of-work system similar to Adam Back's Hashcash, rather than newspaper or Usenet posts. The proof-of-work involves scanning for a value that when hashed, such as with SHA-256, the hash begins with a number of zero bits. The average work required is exponential in the number of zero bits required and can be verified by executing a single hash.

For our timestamp network, we implement the proof-of-work by incrementing a nonce in the block until a value is found that gives the block's hash the required zero bits. Once the CPU effort has been expended to make it satisfy the proof-of-work, the block cannot be changed without redoing the work. As later blocks are chained after it, the work to change the block would include redoing all the blocks after it.

Proof-of-work also solves the problem of determining representation in majority decision making. If the majority were based on one-IP-address-one-vote, it could be subverted by anyone able to allocate many IPs. Proof-of-work is essentially one-CPU-one-vote. The majority decision is represented by the longest chain, which has the greatest proof-of-work effort invested in it (`nChainWork`).

To compensate for increasing hardware speed and varying interest in running nodes over time, the proof-of-work difficulty is determined by a moving average targeting an average number of blocks per hour. If they're generated too fast, the difficulty increases.

> **Bitcoin Core C++ Mapping:**
> - `CheckProofOfWork` & `GetNextWorkRequired` (2016-block difficulty adjustment) -> [`/Users/mac/bitcoin/src/pow.cpp`](file:///Users/mac/bitcoin/src/pow.cpp)

---

## 5. Network
The steps to run the network are as follows:
1. New transactions are broadcast to all nodes.
2. Each node collects new transactions into a block.
3. Each node works on finding a difficult proof-of-work for its block.
4. When a node finds a proof-of-work, it broadcasts the block to all nodes.
5. Nodes accept the block only if all transactions in it are valid and not already spent.
6. Nodes express their acceptance of the block by working on creating the next block in the chain, using the hash of the accepted block as the previous hash.

Nodes always consider the longest chain (`most cumulative proof-of-work`) to be the correct one and will keep working on extending it.

> **Bitcoin Core C++ Mapping:**
> - P2P message handling (`inv`, `getdata`, `tx`, `block`, `headers`, `cmpctblock`) -> [`/Users/mac/bitcoin/src/net_processing.cpp`](file:///Users/mac/bitcoin/src/net_processing.cpp)
> - Chain validation & `ActivateBestChain` -> [`/Users/mac/bitcoin/src/validation.cpp`](file:///Users/mac/bitcoin/src/validation.cpp)

---

## 6. Incentive
By convention, the first transaction in a block is a special transaction that starts a new coin owned by the creator of the block (`coinbase`). This adds an incentive for nodes to support the network, and provides a way to initially distribute coins into circulation, since there is no central authority to issue them. The steady addition of a constant of amount of new coins is analogous to gold miners expending resources to add gold to circulation. In our case, it is CPU time and electricity that is expended.

The incentive can also be funded with transaction fees. If the output value of a transaction is less than its input value, the difference is a transaction fee that is added to the incentive value of the block containing the transaction. Once a predetermined number of coins have entered circulation (`21,000,000 BTC`), the incentive can transition entirely to transaction fees and be completely inflation free.

> **Bitcoin Core C++ Mapping:**
> - `GetBlockSubsidy` -> [`/Users/mac/bitcoin/src/validation.cpp`](file:///Users/mac/bitcoin/src/validation.cpp)
> - `COINBASE_MATURITY = 100` -> [`/Users/mac/bitcoin/src/consensus/consensus.h`](file:///Users/mac/bitcoin/src/consensus/consensus.h)
> - `txfee_aux = nValueIn - value_out` -> [`/Users/mac/bitcoin/src/consensus/tx_verify.cpp`](file:///Users/mac/bitcoin/src/consensus/tx_verify.cpp)

---

## 7. Reclaiming Disk Space (Merkle Trees)
Once the latest transaction in a coin is buried under enough blocks, the spent transactions before it can be discarded to save disk space. To facilitate this without breaking the block's hash, transactions are hashed in a Merkle Tree, with only the root included in the block's hash.

> **Bitcoin Core C++ Mapping:**
> - `ComputeMerkleRoot` & `BlockMerkleRoot` -> [`/Users/mac/bitcoin/src/consensus/merkle.cpp`](file:///Users/mac/bitcoin/src/consensus/merkle.cpp)

---

## 8. Simplified Payment Verification (SPV)
It is possible to verify payments without running a full network node. A user only needs to keep a copy of the block headers of the longest proof-of-work chain (`80 bytes` per block = `4.2 MB` per year), which he can get by querying network nodes until he's convinced he has the longest chain, and obtain the Merkle branch linking the transaction to the block it's timestamped in.

---

## 9. Combining and Splitting Value (UTXO Fan-In / Fan-Out)
Although it would be possible to handle coins individually, it would be unwieldy to make a separate transaction for every cent in a transfer. To allow value to be split and combined, transactions contain multiple inputs and outputs. Normally there will be either a single input from a larger previous transaction or multiple inputs combining smaller amounts, and at most two outputs: one for the payment, and one returning the change, if any, back to the sender.

---

## 10. Privacy
The traditional banking model achieves a level of privacy by limiting access to information to the parties involved and the trusted third party. The necessity to announce all transactions publicly precludes this method, but privacy can still be maintained by breaking the flow of information in another place: by keeping public keys anonymous (`pseudonymous`). As an additional firewall, a new key pair should be used for each transaction to keep them from being linked to a common owner.

---

## 11. Calculations & 12. Conclusion
We have proposed a system for electronic transactions without relying on trust. We started with the usual framework of coins made from digital signatures, which provides strong control of ownership, but is incomplete without a way to prevent double-spending. To solve this, we proposed a peer-to-peer network using proof-of-work to record a public history of transactions that quickly becomes computationally impractical for an attacker to change if honest nodes control a majority of CPU power.
