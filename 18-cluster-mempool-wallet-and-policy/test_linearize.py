#!/usr/bin/env python3
"""Checker for Stage 18 / Exercise 18.2. Loads my-work/18-cluster-mempool-wallet-and-policy/linearize.py (or argv[1]) and
tests chunk(), diagram() and compare() on hand-built clusters. Prints PASS/FAIL with a
reason; never prints the expected chunking."""
import importlib.util
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT = os.path.join(os.path.dirname(HERE), "my-work", "18-cluster-mempool-wallet-and-policy", "linearize.py")


def load(path):
    if not os.path.exists(path):
        print(f"FAIL: {path} not found; copy exercises/linearize_skeleton.py there")
        sys.exit(1)
    spec = importlib.util.spec_from_file_location("learner_linearize", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


fails = 0


def check(ok, msg):
    global fails
    if not ok:
        fails += 1
        print("FAIL: " + msg)


def strip(chunks):
    return [(c[0], c[1], list(c[2])) for c in chunks]


def is_monotone(chunks):
    return all(c1[0] * c0[1] <= c0[0] * c1[1] for c0, c1 in zip(chunks, chunks[1:]))


def main():
    m = load(sys.argv[1] if len(sys.argv) > 1 else DEFAULT)
    try:
        # 1. CPFP: low parent, high child -> one chunk
        r = strip(m.chunk([(100, 100), (900, 100)]))
        check(len(r) == 1 and r[0][:2] == (1000, 200), "CPFP parent+child should form a single chunk")
        # 2. Already decreasing -> each tx its own chunk
        r = strip(m.chunk([(500, 100), (300, 100), (100, 100)]))
        check(len(r) == 3, "a strictly decreasing linearization should not merge anything")
        # 3. Equal feerates must NOT merge (strictly higher only, like ChunkLinearization)
        r = strip(m.chunk([(200, 100), (200, 100)]))
        check(len(r) == 2, "equal feerates must stay separate chunks (merge only on strictly higher)")
        # 4. Cascade merge
        r = strip(m.chunk([(300, 100), (100, 100), (100, 100), (1000, 100)]))
        check(len(r) == 1 and r[0][2] == [0, 1, 2, 3], "a high-fee last tx should cascade-merge back through every lower chunk")
        # 5. Random: invariants (monotone, sums preserved, indices in order)
        rng = random.Random(1337)
        for _ in range(300):
            lin = [(rng.randrange(0, 5000), rng.randrange(60, 400)) for _ in range(rng.randrange(1, 12))]
            r = strip(m.chunk(lin))
            check(is_monotone(r), "chunk feerates must be non-increasing")
            check(sum(c[0] for c in r) == sum(t[0] for t in lin) and sum(c[1] for c in r) == sum(t[1] for t in lin),
                  "chunks must preserve total fee and size")
            check([i for c in r for i in c[2]] == list(range(len(lin))), "chunks must keep linearization order")
            if fails:
                break
        # 6. diagram
        d = m.diagram(m.chunk([(500, 100), (100, 100)]))
        check(list(map(tuple, d)) == [(0, 0), (100, 500), (200, 600)], "diagram should be cumulative (size, fee) from (0, 0)")
        # 7. compare
        a = m.chunk([(1000, 200)])
        b = m.chunk([(900, 200)])
        check(m.compare(a, b) == "better" and m.compare(b, a) == "worse", "higher total fee at same size should be 'better'")
        check(m.compare(a, a) == "equal", "a diagram compared with itself is 'equal'")
        c = m.chunk([(600, 100), (100, 100)])   # fast start, slow end: 700 total
        e = m.chunk([(400, 100), (400, 100)])   # slow start, 800 total
        check(m.compare(c, e) == "incomparable", "crossing diagrams must be 'incomparable'")
        # replacement shaped like the RBF 'feerate diagram must strictly improve' rule
        old = m.chunk([(100, 100), (900, 100)])  # CPFP pair
        new = m.chunk([(1100, 150)])             # replacement: smaller, more fee
        check(m.compare(new, old) == "better", "smaller replacement paying more fee should strictly improve the diagram")
    except NotImplementedError:
        print("FAIL: a function still raises NotImplementedError")
        sys.exit(1)
    if fails:
        print(f"RESULT: FAIL ({fails})")
        sys.exit(1)
    print("RESULT: PASS")


if __name__ == "__main__":
    main()
