#!/usr/bin/env python3
"""Test Multi-Node P2P Relay, BIP125 RBF DoS Rules, and CPFP Ancestor Packages."""

from decimal import Decimal
import os
import sys

BITCOIN_ROOT = os.environ.get("BITCOIN_ROOT", "/Users/mac/bitcoin")
sys.path.insert(0, os.path.join(BITCOIN_ROOT, "test/functional"))

from test_framework.messages import MAX_BIP125_RBF_SEQUENCE
from test_framework.test_framework import BitcoinTestFramework
from test_framework.util import (
    assert_equal,
    assert_raises_rpc_error,
)
from test_framework.wallet import MiniWallet


class KisumuPosRbfCpfpTest(BitcoinTestFramework):
    def set_test_params(self):
        self.num_nodes = 2
        self.supports_cli = False

    def run_test(self):
        customer_node = self.nodes[0]
        merchant_node = self.nodes[1]

        self.wallet = MiniWallet(customer_node)
        utxo = self.wallet.get_utxo()

        self.log.info("1. Broadcasting initial low-fee RBF transaction (200 sats) on Node 0...")
        tx_v1 = self.wallet.create_self_transfer(
            utxo_to_spend=utxo,
            sequence=MAX_BIP125_RBF_SEQUENCE,
            fee=Decimal("0.00000200"),
        )
        customer_node.sendrawtransaction(tx_v1["hex"])
        self.sync_mempools()

        assert tx_v1["txid"] in merchant_node.getrawmempool()
        entry_v1 = merchant_node.getmempoolentry(tx_v1["txid"])
        assert_equal(entry_v1["bip125-replaceable"], True)
        assert_equal(entry_v1["fees"]["base"], Decimal("0.00000200"))

        self.log.info("2. Verifying PaysForRBF Rule #4 rejection (+50 sats < incremental relay fee)...")
        tx_v2_bad = self.wallet.create_self_transfer(
            utxo_to_spend=utxo,
            sequence=MAX_BIP125_RBF_SEQUENCE,
            fee=Decimal("0.00000250"),
        )
        assert_raises_rpc_error(
            -26,
            "not enough additional fees to relay",
            customer_node.sendrawtransaction,
            tx_v2_bad["hex"],
        )

        self.log.info("3. Broadcasting valid BIP125 replacement (5,000 sats) and verifying P2P eviction...")
        tx_v2_good = self.wallet.create_self_transfer(
            utxo_to_spend=utxo,
            sequence=MAX_BIP125_RBF_SEQUENCE,
            fee=Decimal("0.00005000"),
        )
        customer_node.sendrawtransaction(tx_v2_good["hex"])
        self.sync_mempools()

        assert tx_v1["txid"] not in customer_node.getrawmempool()
        assert tx_v1["txid"] not in merchant_node.getrawmempool()
        assert tx_v2_good["txid"] in merchant_node.getrawmempool()

        self.log.info("4. Broadcasting high-fee CPFP child (20,000 sats) from Merchant Node 1...")
        tx_child = self.wallet.create_self_transfer(
            utxo_to_spend=tx_v2_good["new_utxo"],
            fee=Decimal("0.00020000"),
        )
        merchant_node.sendrawtransaction(tx_child["hex"])
        self.sync_mempools()

        child_entry = customer_node.getmempoolentry(tx_child["txid"])
        assert_equal(child_entry["ancestorcount"], 2)
        assert_equal(child_entry["fees"]["ancestor"], Decimal("0.00025000"))
        assert_equal(child_entry["depends"], [tx_v2_good["txid"]])

        self.log.info("5. Mining confirmation block and verifying topological ordering...")
        block_hash = self.generate(customer_node, 1)[0]
        block = merchant_node.getblock(block_hash)
        assert_equal(block["tx"][1], tx_v2_good["txid"])
        assert_equal(block["tx"][2], tx_child["txid"])


if __name__ == "__main__":
    KisumuPosRbfCpfpTest(__file__).main()
