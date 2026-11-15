# Stage 14 quiz answers (spoilers)

1. `wtxidrelay` (BIP339), `sendaddrv2` (BIP155), `sendtxrcncl` (Erlay), and on master `feature` (BIP434). After `verack` Core logs and disconnects the peer (`fDisconnect = true`) without `Misbehaving`.
2. `CConnman` in `src/net.{h,cpp}` owns sockets, threads and `CNode`s; `PeerManagerImpl` in `src/net_processing.cpp` interprets messages.
3. Misbehavior used to add a score and only discourage at 100. PR #29575 made every `Misbehaving` call discourage immediately (no score). Discouraged addresses are not banned: they may still connect inbound but are preferred for eviction and not used for outbound; a ban refuses connections entirely and is set by the operator.
4. They relay no transactions and no addresses, so a spy cannot learn of them by watching tx or addr propagation; the attacker does not know which of your peers they are, which makes partitioning (eclipse) harder.
5. To test addresses from the new table and move good ones to tried, keeping addrman fresh. About every 2 minutes (`FEELER_INTERVAL`).
6. New entries map to buckets by (address group, source group) with a limited number of buckets per source group (64) and tried entries to a limited number of buckets per group (8); each bucket has 64 slots. One /16 can therefore occupy only a small, bounded fraction of the tables.
7. Passive eavesdropping and silent tampering by on-path observers (encrypted, authenticated stream, pseudorandom bytes). It does not authenticate the peer's identity, so an active man-in-the-middle can still terminate both sides.
8. To hide which node first announced a tx: a spy with many inbound connections gets announcements at one shared random time per network group, so timing reveals much less about the origin.
9. Global token-bucket rate limits for inbound and outbound tx announcements with a backlog (PR #34628); option `-txsendrate`.
10. Messages from one peer are processed in order by the message handler thread; a `pong` for our `ping` is only sent after every earlier message from us was processed.
