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

## Checkable facts

After you have answered the questions above in your journal, put these short answers in
`my-work/14-p2p-and-net-processing/answers.env` (one `KEY=value` per line) and run
`python3 tools/check_facts.py 14-p2p-and-net-processing 14.2` from the lab root (or `./lab.sh check 14`).
Answers are for master `e75b76b12c`. The checker says which ones are wrong, never the right value.
Your explanations (the "why" questions) are not machine-checked: compare them with `solutions/` afterwards.

| Key | Question |
|---|---|
| `F14_DISCOURAGE_MUTEX` | q4: the mutex that guards `m_should_discourage` |
| `F14_EVICT_FUNCTION` | q5: the function that picks the inbound peer to evict |
| `F14_NEW_BUCKET_FN` | q7: the method that computes the new-table bucket |
| `F14_TRIED_BUCKET_FN` | q7: the method that computes the tried-table bucket |
| `F14_MAX_LOCATOR_SZ` | q9: the value of `MAX_LOCATOR_SZ` |
| `F14_INBOUND_INV_SECONDS` | q6: the average inbound inventory broadcast interval, in seconds |
