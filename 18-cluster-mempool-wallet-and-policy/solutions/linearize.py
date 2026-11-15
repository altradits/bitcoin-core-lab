#!/usr/bin/env python3
"""SPOILER: reference for Stage 18 / Exercise 18.2 (chunking and feerate diagrams).

Mirrors, in Python, master's
  src/cluster_linearize.h  ChunkLinearization / ChunkLinearizationInfo
  src/util/feefrac.{h,cpp}  FeeFrac ordering and CompareChunks
Open only after test_linearize.py passes on your own my-work/18-cluster-mempool-wallet-and-policy/linearize.py.
"""


def higher_feerate(a, b):
    """True if (fee_a/size_a) > (fee_b/size_b), compared without division (like FeeFrac)."""
    return a[0] * b[1] > b[0] * a[1]


def chunk(linearization):
    """linearization: list of (fee, size) in a topologically valid order.
    Returns a list of chunks, each (fee, size, [indices into linearization])."""
    chunks = []
    for i, (fee, size) in enumerate(linearization):
        new = (fee, size, [i])
        while chunks and higher_feerate(new, chunks[-1]):
            pf, ps, pidx = chunks.pop()
            new = (new[0] + pf, new[1] + ps, pidx + new[2])
        chunks.append(new)
    return chunks


def diagram(chunks):
    """Cumulative (size, fee) points starting at (0, 0)."""
    pts = [(0, 0)]
    for fee, size, _ in chunks:
        pts.append((pts[-1][0] + size, pts[-1][1] + fee))
    return pts


def _fee_at(pts, x):
    """Fee of the piecewise-linear diagram at size x, as a fraction (num, den).
    Beyond the end the diagram is flat (no more fees)."""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x0 <= x <= x1:
            # y0 + (y1-y0)*(x-x0)/(x1-x0)
            return (y0 * (x1 - x0) + (y1 - y0) * (x - x0), (x1 - x0))
    return (pts[-1][1], 1)


def compare(chunks_a, chunks_b):
    """Return 'better', 'worse', 'equal' or 'incomparable' for diagram A vs diagram B,
    comparing the cumulative fee at every breakpoint of either diagram (like CompareChunks)."""
    pa, pb = diagram(chunks_a), diagram(chunks_b)
    xs = sorted({x for x, _ in pa} | {x for x, _ in pb})
    a_higher = b_higher = False
    for x in xs:
        fa, da = _fee_at(pa, x)
        fb, db = _fee_at(pb, x)
        if fa * db > fb * da:
            a_higher = True
        elif fa * db < fb * da:
            b_higher = True
    if a_higher and b_higher:
        return "incomparable"
    if a_higher:
        return "better"
    if b_higher:
        return "worse"
    return "equal"
