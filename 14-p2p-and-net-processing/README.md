# Stage 14: P2P, `net` and `net_processing`

> **Source checked for this stage.** This stage teaches **`master`** at **`e75b76b12c`**
> (`Merge bitcoin/bitcoin#35261: guix: disable LTO in GCC`), checked with `git grep <pat> master` and
> `git show master:<path>`. The 29.x commit **`f490f5562d`** (your old working tree) was checked too.
> Differences are marked **"29.x → master"**. Function names are given without line numbers on purpose,
> because `net_processing.cpp` moves every week. Find them with `git grep -n`.

Most of a node's attack surface is here: every byte a stranger sends arrives through `net.cpp` and
is interpreted by `net_processing.cpp`. Reviewers of P2P PRs ask one question again and again:
**"What can a peer make us do, and how much does it cost us?"**

**No-shortcuts rule.** Worksheets say what to achieve and which RPC, option or file to use. They never give the
finished command. Save every command in `my-work/14-p2p-and-net-processing/journal.md`. Open `solutions/`
only after `./check_14.sh` passes, or after three honest attempts.

---

## Objectives

| ID | You can... |
|---|---|
| C-P2P-1 | Name the messages in the version/verack handshake and the feature negotiation that must happen between them. Explain the `net` vs `net_processing` split. |
| C-P2P-2 | Explain inv/getdata/tx relay, trickling, Poisson timers, wtxid relay (BIP339) and how master rate-limits announcements. |
| C-P2P-3 | Explain compact blocks (BIP152): `sendcmpct`, high-bandwidth vs low-bandwidth, short IDs, `getblocktxn`/`blocktxn`. |
| C-P2P-4 | Explain addrman's new/tried tables and buckets, the connection types (including block-relay-only and feelers), anchors, and why this resists eclipse attacks. |
| C-P2P-5 | Explain what BIP324 v2 transport protects against and where it lives (`src/bip324.cpp`, `V2Transport` in `src/net.h`). |
| C-P2P-6 | Explain the current misbehavior model (any misbehavior means discouragement) and how per-peer resources are bounded. |
| C-CPP-2 | Read `GUARDED_BY` / `EXCLUSIVE_LOCKS_REQUIRED` on `Peer`, `CNodeState` and `PeerManagerImpl`, and say which mutex protects what. |
| C-CPP-3 | Decode a P2P message with the serialization framework (`CBlockLocator`, `CInv`, CompactSize). |
| C-PY-2 | Write a functional test with `P2PInterface` that sends a raw message and asserts the node's reaction. |

**Prerequisites:** Stage 13 (you can build `master` on a topic branch and read the C++), Stage 04 (functional test framework).
**Estimated time:** 18 hours.
**RAM note (8 GB).** Exercise 1 runs **two** regtest nodes with small caches. That is about 200–400 MB together, which
is fine for regtest. Never run a mainnet or signet node at the same time. The repo convention "one `bitcoind` at a time"
is about authoring and heavy networks. For this exercise, stop everything else first. A third node is optional.

---

## Theory

### 1. The split: `CConnman` (net.cpp) vs `PeerManager` (net_processing.cpp)

| Layer | Class (file) | Owns |
|---|---|---|
| Sockets and connections | `CConnman` (`src/net.h`, `src/net.cpp`) | Threads such as `ThreadSocketHandler`, `ThreadOpenConnections` and `ThreadMessageHandler`; the list of `CNode`s; deciding *whom* to connect to (using `AddrMan`); eviction of inbound peers (`SelectNodeToEvict` in `src/node/eviction.cpp`). |
| Per-connection transport | `CNode` + `Transport` (`V1Transport`, `V2Transport` in `src/net.h`) | Bytes to messages: framing, checksums (v1) or encryption (v2, `BIP324Cipher` in `src/bip324.h`). |
| Protocol logic | `PeerManagerImpl` (`src/net_processing.cpp`) | `ProcessMessages` → `ProcessMessage` (one big `if (msg_type == NetMsgType::...)` chain), `SendMessages`. Holds `Peer` (`struct Peer`) and `CNodeState` per peer. Block download, header sync, tx download (`src/node/txdownloadman_impl.cpp`), misbehavior. |
| Wire constants | `src/protocol.h` | `namespace NetMsgType` (`"version"`, `"verack"`, `"inv"`...), service flags, `CInv`. |

The message handler thread calls `PeerManagerImpl::ProcessMessages(...)` for one message per peer per loop,
then `SendMessages(...)` for that peer. That loop is why a functional test's **ping/pong round trip**
(`sync_with_ping`) proves that earlier messages were processed.

### 2. The handshake and feature negotiation (C-P2P-1)

1. The outbound side sends `version` (`PushNodeVersion`). The inbound side replies with its own `version`.
2. **Between `version` and `verack`**, peers announce optional features: `wtxidrelay` (BIP339), `sendaddrv2`
   (BIP155), `sendtxrcncl` (Erlay reconciliation; not on by default), and on master `feature` (BIP434 peer feature
   negotiation, merged PR **#35221**; 29.x → master: new).
3. `verack` marks the connection `fSuccessfullyConnected`. **Sending `wtxidrelay`, `sendaddrv2` or `feature`
   after `verack` gets you disconnected.** Read the handlers in `ProcessMessage`: they set `pfrom.fDisconnect = true`
   without calling `Misbehaving`. You will test this in Exercise 3.
4. After verack: `sendheaders` (BIP130), `sendcmpct` (BIP152), `feefilter` (BIP133), `getaddr`, and pings.

### 3. Block sync: headers-first and anti-DoS headers sync

- A node asks for **headers** (`getheaders` with a `CBlockLocator`; reply up to `MAX_HEADERS_RESULTS` = 2000),
  validates proof of work on headers, then requests blocks in parallel (`MAX_BLOCKS_IN_TRANSIT_PER_PEER` = 16).
- Since PR **#25717** (`p2p: Implement anti-DoS headers sync`), a peer whose chain does not yet have
  `MinimumChainWork` goes through `HeadersSyncState` (`src/headerssync.h`). It has a **PRESYNC** phase (keep only
  a compressed commitment of the headers) and a **REDOWNLOAD** phase (download again and store them only once the work is
  proven). This stops low-work header spam from filling memory.
- `getheaders` locators with more than `MAX_LOCATOR_SZ` (101) entries get the peer disconnected.

### 4. Compact blocks (BIP152, C-P2P-3)

`src/blockencodings.{h,cpp}`: `CBlockHeaderAndShortTxIDs` (header + 6-byte short IDs + prefilled txs) and
`PartiallyDownloadedBlock` (fill from mempool, then ask for the rest with `getblocktxn`/`blocktxn`).
High-bandwidth mode lets up to 3 peers push `cmpctblock` *before* full validation. See
`MaybeSetPeerAsAnnouncingHeaderAndIDs`. Reviewer question: *what if a short-ID collision or a missing
tx makes us round-trip, and can a peer force that on purpose?*

### 5. Transaction relay and privacy (C-P2P-2)

- Announce with `inv` (wtxid for BIP339 peers, `MSG_WTX`), fetch with `getdata`, deliver with `tx`.
  Download scheduling lives in `TxRequestTracker` and `src/node/txdownloadman_impl.cpp`.
- **Trickling / Poisson timers:** announcements are batched and sent at random exponential intervals:
  `INBOUND_INVENTORY_BROADCAST_INTERVAL` (5 s average, one timer shared by all inbound peers in a network group,
  see `NextInvToInbounds`) and `OUTBOUND_INVENTORY_BROADCAST_INTERVAL` (2 s, per peer), using `rand_exp_duration`.
  This makes it harder for a spy who connects to many nodes to tell which node sent a transaction first.
- **29.x → master: rate limiting changed.** 29.x limited each peer's queue (`INVENTORY_BROADCAST_PER_SECOND` = 7,
  `INVENTORY_BROADCAST_TARGET`, `INVENTORY_BROADCAST_MAX`). Master merged PR **#34628** (`p2p: Replace per-peer
  transaction rate-limiting with global rate limits`). It uses **global** token buckets with a backlog
  (`m_inbound_inv_bucket`, `m_outbound_inv_bucket`), a new option `-txsendrate` (`DEFAULT_TX_SEND_RATE` = 14 in
  `src/net_processing.h`) and a functional test `p2p_tx_relay_rate_limit.py`.
- **29.x → master: private broadcast.** PR **#29415** (`Broadcast own transactions only via short-lived Tor or I2P
  connections`) added the connection type `PRIVATE_BROADCAST` (`"private-broadcast"`) and the option `-privatebroadcast`.
- `feefilter` (BIP133) tells peers not to announce transactions below our mempool minimum. It is sent at random
  intervals (`AVG_FEEFILTER_BROADCAST_INTERVAL` = 10 min).

### 6. Addresses, addrman and eclipse resistance (C-P2P-4)

- `addr` / `addrv2` (BIP155 adds Tor v3, I2P, CJDNS; PR **#19954**). Up to `MAX_ADDR_TO_SEND` (1000) per message,
  with a token bucket limiting how many addresses per peer we process.
- `AddrMan` (`src/addrman.h`, `src/addrman_impl.h`, `src/addrman.cpp`): a **new** table of
  `2^ADDRMAN_NEW_BUCKET_COUNT_LOG2` = 1024 buckets and a **tried** table of 256 buckets, each with
  `2^ADDRMAN_BUCKET_SIZE_LOG2` = 64 slots. The bucket is chosen by a keyed hash of the address **group** (/16 for IPv4,
  or the AS number with `-asmap`) and, for new entries, the **source** group (`ADDRMAN_NEW_BUCKETS_PER_SOURCE_GROUP` = 64,
  `ADDRMAN_TRIED_BUCKETS_PER_GROUP` = 8). So one attacker IP range can fill only a small part of the tables.
- **Connection types** (`enum class ConnectionType`, `src/node/connection_types.h`): `INBOUND`,
  `OUTBOUND_FULL_RELAY` (8, `MAX_OUTBOUND_FULL_RELAY_CONNECTIONS`), `BLOCK_RELAY` (2,
  `MAX_BLOCK_RELAY_ONLY_CONNECTIONS`; no tx or addr relay, so harder to fingerprint), `FEELER` (short-lived, every
  `FEELER_INTERVAL` = 2 min, tests new-table addresses before moving them to tried), `ADDR_FETCH`, `MANUAL`,
  and on master `PRIVATE_BROADCAST`.
- **Anchors:** on shutdown the block-relay-only peers are saved to `anchors.dat` (`MAX_BLOCK_RELAY_ONLY_ANCHORS` = 2)
  and reconnected first on restart. An attacker cannot simply wait for you to reboot.
- Inbound eviction (`SelectNodeToEvict`, `ProtectEvictionCandidatesByRatio`) protects peers by several
  hard-to-fake qualities (low ping, recently relayed blocks or txs, network diversity).

### 7. BIP324 v2 transport (C-P2P-5)

PR **#28331** (`BIP324 integration`). `-v2transport` defaults to on (`DEFAULT_V2_TRANSPORT`). An ECDH handshake
uses ElligatorSwift-encoded keys, so the bytes look random, followed by ChaCha20-Poly1305 authenticated encryption. It defeats
**passive** observers and makes message tampering detectable. It does **not** authenticate *who* the peer is.
`getpeerinfo` shows `transport_protocol_type` (`v1`, `v2`, or `detecting`) and a `session_id`.

### 8. Misbehavior and DoS (C-P2P-6)

- **Today (both 29.x and master):** `PeerManagerImpl::Misbehaving(Peer&, message)` sets `peer.m_should_discourage = true`
  (guarded by `m_misbehavior_mutex`) and logs at `-debug=net`. `MaybeDiscourageAndDisconnect` then disconnects the peer and,
  unless the peer has `noban` permission or is a manual connection, adds its address to the **discouraged** filter
  (`BanMan::Discourage`). Discouraged addresses are not banned. They can still connect inbound, but they are the first
  evicted.
- **How it changed:** before PR **#29575** (`net_processing: make any misbehavior trigger immediate discouragement`,
  merged for v28), `Misbehaving` took a score and discouraged at 100. Many offences scored 10 or 20, so a peer could
  misbehave a little and stay. Verify it yourself with `git log --oneline --grep=29575` and read the merged commits
  (`6457c31197 net_processing: make all Misbehaving increments = 100`).
- Bounding per-peer cost: message size limits, `MAX_INV_SZ`, `MAX_LOCATOR_SZ`, addr token buckets, the orphanage
  limits, `MAX_BLOCKS_IN_TRANSIT_PER_PEER`, and HeadersSync. Reviewer habit: for every new message or container, find the cap.

---

## Exercises

| # | Worksheet | Produces | Checked by |
|---|---|---|---|
| 1 | [`01_two_node_lab.md`](./exercises/01_two_node_lab.md): you configure two (optionally three) regtest nodes, connect them in different connection types, and read `-debug=net` and `getpeerinfo` | journal + running nodes | `./check_14.sh nodes` |
| 2 | [`02_read_net_vs_net_processing.md`](./exercises/02_read_net_vs_net_processing.md): code-reading questions on the handshake, `Misbehaving`, trickling and addrman | journal answers | `python3 tools/check_facts.py` (facts) + self-check |
| 3 | [`03_p2p_kisumu_handshake_test.py`](./exercises/03_p2p_kisumu_handshake_test.py): a **skeleton** functional test with `P2PInterface`. Ping/pong, getheaders/headers, and "late wtxidrelay = disconnect" | your test, passing | `./check_14.sh test` |
| 4 | [`04_read_upstream_p2p_tests.md`](./exercises/04_read_upstream_p2p_tests.md): read and run `p2p_handshake.py`, `p2p_v2_transport.py`, `p2p_tx_privacy.py`, `p2p_invalid_messages.py` | journal answers | self-check |

---

## Checkpoint

```bash
./lab.sh check 14
```

Runs: ./check_14.sh (nodes, then your P2P test), python3 ../tools/check_facts.py . (the "Checkable facts" of exercise 2). Each prints PASS/FAIL with a reason, never the answer. Run `./check_14.sh nodes` or `./check_14.sh test` to check one part.
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_14=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).

1. Which messages may only appear between `version` and `verack`, and what does Core do if they arrive later?
2. Name the class that owns sockets and the class that interprets messages. Which file holds each?
3. What changed in PR #29575, and why is "discourage" not the same as "ban"?
4. Why are block-relay-only connections harder for an attacker to detect than full-relay ones?
5. What is a feeler connection for? How often does one run?
6. How do addrman's bucket rules limit how much of the table one /16 can take?
7. What does BIP324 protect against, and what does it *not* protect against?
8. Why are inbound tx announcements trickled on a shared Poisson timer? What attack does that slow down?
9. On master, what replaced the per-peer `INVENTORY_BROADCAST_PER_SECOND` limit? Name the option that controls it.
10. In a functional test, why does `send_and_ping` prove that the node processed your earlier message?

---

## Review lens

**Files:** `src/net_processing.cpp`, `src/net.{h,cpp}`, `src/protocol.h`, `src/addrman*.{h,cpp}`,
`src/node/connection_types.h`, `src/node/eviction.cpp`, `src/node/txdownloadman_impl.cpp`, `src/headerssync.cpp`,
`src/blockencodings.cpp`, `src/bip324.cpp`, `test/functional/p2p_*.py`, `src/test/fuzz/process_message*.cpp`.

**Invariants to protect:**
- Every peer-controlled allocation or loop is bounded (count, bytes, time).
- No peer can trigger an `assert`/`Assert`, unbounded logging, or long work while holding `cs_main`.
- Feature negotiation stays inside the version/verack window. Changing message order is a protocol change.
- Lock order: `PeerManagerImpl` locks (`m_peer_mutex`, `cs_main`, per-peer mutexes) follow the annotated order.
  Look for new `EXCLUSIVE_LOCKS_REQUIRED(!...)` annotations.
- Privacy: no new timing or response difference that lets a spy fingerprint the node or link a tx to its origin.
- Eclipse resistance: changes to addrman bucketing, anchors or eviction must not make it cheaper for one network group to dominate.

**Questions to ask on a P2P PR:**
1. What can a peer send to reach this code, and what is the worst-case CPU, memory and bandwidth per message?
2. Does it change behavior visible to other implementations (BIP compliance, message order)? Is a BIP updated?
3. Should a violation be `Misbehaving` (discourage), a plain disconnect, or ignored? Why?
4. Is there a functional test with `P2PInterface` that sends the bad input, and a fuzz harness (`process_message`)?
5. Does it touch `m_tx_inventory_to_send` / the inv buckets, and could that leak tx origin?

**Real merged PRs (verified with `git log --oneline --grep` on master):**
- **#29575**: `net_processing: make any misbehavior trigger immediate discouragement` (merge `a52837b9e9`).
- **#28331**: `BIP324 integration` (merge `6f882e6f86`).
- **#34628**: `p2p: Replace per-peer transaction rate-limiting with global rate limits` (merge `b33a7fcd7b`).
- Also worth reading: #18044 `Use wtxid for transaction relay`, #19954 `Complete the BIP155 implementation and upgrade to TORv3`,
  #25717 `p2p: Implement anti-DoS headers sync`, #29415 private broadcast.

---

## Proof-of-work output

1. Your `p2p_kisumu_handshake_test.py`, published as a gist with a short write-up: "What happens if a peer sends
   `wtxidrelay` after `verack`, and why disconnect without discouraging?"
2. Prepare for the next **Bitcoin Core PR Review Club** meeting that covers a P2P PR (check bitcoincore.reviews).
   Post your own answers in the meeting. Use this stage's Review lens questions as your prep notes.
3. Present the two-node `getpeerinfo` comparison (connection types, v1 vs v2) at a BitDevs Kisumu session.
