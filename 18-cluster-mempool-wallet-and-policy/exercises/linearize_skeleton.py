#!/usr/bin/env python3
"""Stage 18 / Exercise 18.2 skeleton: chunks and feerate diagrams by hand.

Copy to my-work/18-cluster-mempool-wallet-and-policy/linearize.py and fill in every TODO. Standard library only.
Read first (on master):
  git -C ~/bitcoin show master:doc/policy/mempool-design.md
  git -C ~/bitcoin show master:src/cluster_linearize.h   (search: ChunkLinearization)
  git -C ~/bitcoin show master:src/util/feefrac.h        (search: CompareChunks, FeeFrac)
Then run: python3 18-cluster-mempool-wallet-and-policy/test_linearize.py

A transaction is a tuple (fee_in_sats, size_in_vbytes). Never divide: compare feerates by
cross-multiplication, exactly like FeeFrac does, so you never hit float rounding.
"""


def higher_feerate(a, b):
    """True if a's feerate is strictly higher than b's. a and b start with (fee, size, ...)."""
    # TODO
    raise NotImplementedError


def chunk(linearization):
    """linearization: list of (fee, size) already in a topologically valid order.
    Return the chunking as a list of (fee, size, [indices]) with chunk feerates
    monotonically non-increasing. Hint: one pass, a stack, merge while the new
    chunk beats the previous one."""
    # TODO
    raise NotImplementedError


def diagram(chunks):
    """Return the feerate diagram: list of cumulative (size, fee) points, starting at (0, 0)."""
    # TODO
    raise NotImplementedError


def compare(chunks_a, chunks_b):
    """Compare diagram A with diagram B. Return exactly one of:
    'better' (A >= B everywhere and > somewhere), 'worse', 'equal', 'incomparable'.
    Where do you need to evaluate the diagrams? (Think: every breakpoint of either one,
    and the diagrams are straight lines between breakpoints.)"""
    # TODO
    raise NotImplementedError
