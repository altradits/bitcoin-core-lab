# Stage 14 Exercise 2: Read `net` vs `net_processing`

**Output:** journal answers. **Check:** compare with [`../solutions/reading_answers.md`](../solutions/reading_answers.md)
only after you answered all of them.

Use `git grep -n <pattern> master -- src/` (master) and plain `git grep` (your 29.x tree). Give
file + function for every answer, not line numbers.

1. Where is `PushNodeVersion` called for an outbound peer, and where for an inbound one?
2. In `ProcessMessage`, find the `VERSION` handler. List the checks that can make us disconnect
   before `verack` (at least 3).
3. Find every message handler that sets `fDisconnect` when the message arrives after `verack`.
   Which of them also call `Misbehaving`? Why the difference?
4. `Misbehaving`: what mutex guards `m_should_discourage`? Where is it read, and what decides
   between disconnecting and discouraging?
5. Which function chooses the next inbound peer to evict? Name three properties it protects.
6. Find `NextInvToInbounds`. Why is the timer shared per network group instead of per peer?
7. In `src/addrman_impl.h`, which two methods compute the new-table and tried-table bucket?
   What inputs do they hash?
8. `HeadersSyncState`: what is stored during PRESYNC, and why is that enough to stop memory DoS?
9. Find `MAX_LOCATOR_SZ` and the code that enforces it. What happens to the peer?
10. Pick one `GUARDED_BY(...)` member of `struct Peer` and one of `CNodeState`. Which mutex guards
    each? Why is `CNodeState` still under `cs_main`?
