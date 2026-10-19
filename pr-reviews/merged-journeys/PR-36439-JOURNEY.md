# Merged PR #36439 Review Journey: `test: poll more frequently in sync helpers and RPC connection wait`

- **Author:** `@ViniciusCestarii`
- **Merged At:** `2026-10-16T06:37:42Z`
- **Final Merged Head Commit:** `8898f832d9d86d5a6a8ad8719e1009c702bbf4bd`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-36439` (`git -C /Users/mac/bitcoin show pr-36439`)
- **Core Lesson for Reviewers:** How @maflcko requested benchmark plots for test framework speedups, suggested forcing named keyword arguments (`*, wait=0.05`), and separated valid monotonic-clock nits from 'hallucinated AI slop'.

---

## 1. Original PR Description

```text
Tested on  my x86-64 machine:

- Wall time (-j=18): 110.8s to 96.4s (−13%)
- Accumulated: 1715s to 1369s (−20%)

Also compared the CI on my fork (time for test_runner.py runtime):

- macOS native: [1287s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37308619216/job/111758264512#step:9:4745) to [1175s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37318654530/job/111791769239#step:9:4744) (-9%)
- 32 bit ARM: [776s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37308619216/job/111758264778#step:10:6336) to [690s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37318654530/job/111791769348#step:10:5806) (-11%)
- Windows native, VS: [1456s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37308619216/job/111758264639#step:14:1486) to [1252s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37318654530/job/111791768933#step:14:1486) (-14%)
- previous releases: [930s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37308619216/job/111758264815#step:10:5510) to [786s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37318654530/job/111791769195#step:10:6016) (-15%)
- No wallet: [614s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37308619216/job/111758264997#step:10:5421) to [572s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37318654530/job/111791769524#step:10:5813) (-7%)
- Alpine (musl): [1958s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37308619216/job/111758265011#step:10:5041) to [1970s](https://github.com/ViniciusCestarii/bitcoin/actions/runs/37318654530/job/111791769871#step:10:5489) (+0.6%)

Sanitizer jobs are left out because they vary too much between runs.

Alpine (musl) uses --usecli, so more frequent poll creates a new bitcoin-cli process each time, making it not faster with these changes. Also tried locally with --usecli: from 2060s to 2051s accumulated.
```

## 2. Commit & Diff Stat (`git show --stat pr-36439`)

```text
commit 8898f832d9d86d5a6a8ad8719e1009c702bbf4bd
Author: ViniciusCestarii <viniciuscestari01@gmail.com>
Date:   Wed Oct 14 10:24:38 2026 -0300

    test: poll more frequently in sync helpers and RPC connection wait

 test/functional/test_framework/test_framework.py | 4 ++--
 test/functional/test_framework/test_node.py      | 7 ++++---
 2 files changed, 6 insertions(+), 5 deletions(-)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

### `@maflcko` on `test/functional/test_framework/test_node.py:357` (2026-10-06T07:24:23Z)

```diff
@@ -353,8 +353,8 @@ def create_new_rpc_connection(self, *, mode="AUTO", client_timeout=None):
 
     def wait_for_rpc_connection(self, *, wait_for_import=True):
         """Sets up an RPC connection to the bitcoind process. Returns False if unable to connect."""
-        # Poll at a rate of four times per second
-        poll_per_s = 4
+        # Poll at a rate of twenty times per second
+        poll_per_s = 20
```

> nit: Use a deadline time here as well?

### `@maflcko` on `test/functional/test_framework/test_framework.py:720` (2026-10-06T07:24:30Z)

```diff
@@ -717,7 +717,7 @@ def sync_blocks(self, nodes=None, wait=1, timeout=60):
             "".join("\n  {!r}".format(b) for b in best_hash),
         ))
 
-    def sync_mempools(self, nodes=None, wait=1, timeout=60, flush_scheduler=True):
+    def sync_mempools(self, nodes=None, wait=0.05, timeout=60, flush_scheduler=True):
```

> Pretty sure I tried this one in the past, but it didn't result in a speed-up. I guess back then the trickle relay was used, and dominated. Now, the immediate tx relay is used for most tests and it can help.

### `@ViniciusCestarii` on `test/functional/test_framework/test_node.py:357` (2026-10-06T12:41:00Z)

```diff
@@ -353,8 +353,8 @@ def create_new_rpc_connection(self, *, mode="AUTO", client_timeout=None):
 
     def wait_for_rpc_connection(self, *, wait_for_import=True):
         """Sets up an RPC connection to the bitcoind process. Returns False if unable to connect."""
-        # Poll at a rate of four times per second
-        poll_per_s = 4
+        # Poll at a rate of twenty times per second
+        poll_per_s = 20
```

> Makes sense,  Done in 88d40ec15510a8d029c1eaffbae9c068da18f5f9

### `@ViniciusCestarii` on `test/functional/test_framework/test_framework.py:720` (2026-10-06T13:23:16Z)

```diff
@@ -717,7 +717,7 @@ def sync_blocks(self, nodes=None, wait=1, timeout=60):
             "".join("\n  {!r}".format(b) for b in best_hash),
         ))
 
-    def sync_mempools(self, nodes=None, wait=1, timeout=60, flush_scheduler=True):
+    def sync_mempools(self, nodes=None, wait=0.05, timeout=60, flush_scheduler=True):
```

> Interesting, makes sense.

### `@maflcko` on `test/functional/test_framework/test_framework.py:698` (2026-10-14T12:03:16Z)

```diff
@@ -695,7 +695,7 @@ def create_outpoints(self, node, *, outputs):
             utxos.append({"txid": send_res["txid"], "vout": vout})
         return utxos
 
-    def sync_blocks(self, nodes=None, wait=1, timeout=60):
+    def sync_blocks(self, nodes=None, wait=0.05, timeout=60):
```

> ```suggestion
>     def sync_blocks(self, nodes=None, *, wait=0.05, timeout=60):
> ```
> 
> nit: force named kwargs while touching this line? Same below

### `@ViniciusCestarii` on `test/functional/test_framework/test_framework.py:698` (2026-10-14T13:26:00Z)

```diff
@@ -695,7 +695,7 @@ def create_outpoints(self, node, *, outputs):
             utxos.append({"txid": send_res["txid"], "vout": vout})
         return utxos
 
-    def sync_blocks(self, nodes=None, wait=1, timeout=60):
+    def sync_blocks(self, nodes=None, wait=0.05, timeout=60):
```

> kwargs are nice, done on 0b928e01df34e46e1604a3e9c88acc7b5910b82f

### `@maflcko` on `test/functional/test_framework/test_node.py:366` (2026-10-15T08:57:41Z)

```diff
         latest_error = None
         def suppress_error(category: str, e: Exception):
             suppressed_errors[category] += 1
             return (category, repr(e))
 
-        for _ in range(poll_per_s * self.rpc_timeout):
+        stop_time = time.time() + self.rpc_timeout
+        while time.time() <= stop_time:
```

> <details><summary>nit from the Ralph LLM to use monotonic time.</summary>
> 
> Use a monotonic clock for the RPC startup deadline (test/functional/test_framework/test_node.py:365, head)
> 
> time.time() can jump during startup polling: a forward adjustment can make the loop fail before rpc_timeout elapses, while a backward adjustment can extend the wait. Use time.monotonic() for both deadline creation and comparison. No actual host-clock adjustment during startup was identified, so the impact is conditional on that trigger.
> 
> </details>

### `@ViniciusCestarii` on `test/functional/test_framework/test_node.py:366` (2026-10-15T10:53:49Z)

```diff
         latest_error = None
         def suppress_error(category: str, e: Exception):
             suppressed_errors[category] += 1
             return (category, repr(e))
 
-        for _ in range(poll_per_s * self.rpc_timeout):
+        stop_time = time.time() + self.rpc_timeout
+        while time.time() <= stop_time:
```

> Done in 8898f832d9d86d5a6a8ad8719e1009c702bbf4bd. There are also other tests that use time.time() for measuring duration instead of monotonic that could also be changed, but I guess clock jumping is not common so it is a non issue today.

## 4. General Discussion & Maintainer Feedback Thread

### `@ViniciusCestarii` (2026-10-06T13:20:54Z)

Thanks @maflcko for reviewing. Force-pushed 88d40ec15510a8d029c1eaffbae9c068da18f5f9 addressing https://github.com/bitcoin/bitcoin/pull/36439#discussion_r4192615551

> I think functional tests are run at double saturation (2*nproc) sometimes, so it would be good to check this doesn't regress either.

By what I found, [only the job "test ancestor commits" does it](https://github.com/bitcoin/bitcoin/blob/master/.github/ci-test-each-commit-exec.py#L64). Agree it's worth checking.

> create some plots to show this is an improvement (and to see the performance plot around the values)

Will do.

---

### `@ViniciusCestarii` (2026-10-06T19:08:34Z)

I benchmarked these changes on my x86-64 machine with 20 logic processors:

<img width="960" height="790" alt="image" src="https://github.com/user-attachments/assets/0c346527-71bb-4288-9ca2-22eaf5240f17" />

- master is the baseline and w0.05 is this PR.
- rpc20 is only the `wait_for_rpc_connection` change, sync0.05 is only the sync changes.
- w0.X sets both the sync wait and the RPC connection poll interval to X seconds.
- Wall time is how long the whole suite took, running the tests in parallel.
- The sum is the total of each test's own wall-clock duration, measured while running in parallel.

Most of the gain comes from the sync change and RPC poll change adds a smaller one on top. Below 0.05 there is no further improvement and at -j40 polling faster (w0.01) starts to cost more than it saves, so 0.05 looks like the right value.

It'd be great if others could run it too.

I measured this with this script: https://gist.github.com/ViniciusCestarii/72216066d3707b41b3b5b2292b07055b usign the command:

```
python3 pollbench.py --jobs 20,40 --runs 5 --variants master=1:4,w0.25=0.25:4,w0.1=0.1:10,w0.05=0.05:20,w0.025=0.025:40,w0.01=0.01:100,sync0.05=0.05:4,rpc20=1:20
```

I used AI to help me make this benchmark script and plot the data.

---

### `@maflcko` (2026-10-15T08:56:05Z)

> I used AI to help me make this benchmark script and plot the data.

Nice. I asked an LLM bot to run a few benches on my Travel Laptop (155H cpu).

* It seems that 0.05 is ideal when running tests stand-alone (-j1) on this weaker CPU. On your machine I expect for -j1, that w0.025 may be faster (but not significantly).
* For saturated runs (with or without valgrind), on the 155H machine 0.1 was faster. But I don't really run the tests often on this machine, and there was a lot of noise anyway.
* The valgrind test runs failed (probably due to a small --timeout-factor )

<img src="https://drahtbot.space/temp_scratch/pollbench.png?w"></img>


So I think the takeaway is that 0.05 is a valid choice.

I wonder if some sanitizer-heavy CIs (tsan, msan, asan) will also benefit from this, or is the variance too high to see something here?

---

### `@maflcko` (2026-10-15T09:00:07Z)

Lgtm. Just curious about the sanitizer CI, but not a blocker.

review ACK 0b928e01df34e46e1604a3e9c88acc7b5910b82f 📗

<details><summary>Show signature</summary>

Signature:

```
untrusted comment: signature from minisign secret key on empty file; verify via: minisign -Vm "${path_to_any_empty_file}" -P RWTRmVTMeKV5noAMqVlsMugDDCyyTSbA3Re5AkUrhvLVln0tSaFWglOw -x "${path_to_this_whole_four_line_signature_blob}"
RUTRmVTMeKV5npGrKx1nqXCw5zeVHdtdYURB/KlyA/LMFgpNCs+SkW9a8N95d+U4AP1RJMi+krxU1A3Yux4bpwZNLvVBKy0wLgM=
trusted comment: review ACK 0b928e01df34e46e1604a3e9c88acc7b5910b82f 📗
0IXqiylZQjxuuk6J4C7wqmmSdT8AVA47WEeDErc3gRB7ImQUDzovFJuxaJx4jadY9vJeNQ3eGB8UaLjServ9DQ==
```

</details>

---

### `@maflcko` (2026-10-15T11:44:49Z)

The latest Ralph Review is hallucinated AI slop (https://review.fish.foo/traces/36439-8898f832d9d86d5a6a8ad8719e1009c702bbf4bd-804-4.html). cc @willcl-ark for awareness, but seems fine to just ignore.

Only change is addressing the prior Ralph Review nit.

review ACK 8898f832d9d86d5a6a8ad8719e1009c702bbf4bd 👪

<details><summary>Show signature</summary>

Signature:

```
untrusted comment: signature from minisign secret key on empty file; verify via: minisign -Vm "${path_to_any_empty_file}" -P RWTRmVTMeKV5noAMqVlsMugDDCyyTSbA3Re5AkUrhvLVln0tSaFWglOw -x "${path_to_this_whole_four_line_signature_blob}"
RUTRmVTMeKV5npGrKx1nqXCw5zeVHdtdYURB/KlyA/LMFgpNCs+SkW9a8N95d+U4AP1RJMi+krxU1A3Yux4bpwZNLvVBKy0wLgM=
trusted comment: review ACK 8898f832d9d86d5a6a8ad8719e1009c702bbf4bd 👪
14xsoD5byMfCVUC6Zz159xzCmz5IFtA3/d5pz3EanTOQ9XUI6lwhMh1Cc7X5EUgdyAb2O4WdAMhMdqJYgVEVCQ==
```

</details>

---

## 5. Formal Reviews & Final `ACK`s

### `@maflcko` (`COMMENTED`)

haven't tested this, but it seems fine. I wonder if someone wants to create some plots to show this is an improvement (and to see the performance plot around the values). Also, I think functional tests are run at double saturation (2*nproc) sometimes, so it would be good to check this doesn't regress either.

---
