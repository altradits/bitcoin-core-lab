package main

import (
	"fmt"
	"os/exec"
	"strings"
)

// ============================================================================
// YOUR FIRST BITCOIN PROGRAM (00-start-small/first_app.go)
// ============================================================================
// Goal: Never feel overwhelmed. Every Bitcoin application in the world does
// just 3 basic things with a Bitcoin node:
//   1. Ask the node for the current block height
//   2. Generate a fresh Bitcoin address (bcrt1q...)
//   3. Send satoshis to that address and confirm it in a block
//
// Run this file anytime with:
//   go run first_app.go
// ============================================================================

// askBitcoin runs a bitcoin-cli command against your live local regtest node.
func askBitcoin(args ...string) string {
	baseArgs := []string{"-regtest"}
	baseArgs = append(baseArgs, args...)
	out, err := exec.Command("bitcoin-cli", baseArgs...).CombinedOutput()
	if err != nil {
		return fmt.Sprintf("Error: %v (%s)", err, strings.TrimSpace(string(out)))
	}
	return strings.TrimSpace(string(out))
}

func main() {
	fmt.Println("====================================================")
	fmt.Println("  MY FIRST BITCOIN APP — TALKING TO LIVE BITCOIND")
	fmt.Println("====================================================")

	// ------------------------------------------------------------------------
	// MICRO-CHALLENGE 1: Change this label to your own project name!
	// ------------------------------------------------------------------------
	myProjectLabel := "stanley_first_step"

	// ------------------------------------------------------------------------
	// MICRO-CHALLENGE 2: Change the BTC amount below (e.g., from "0.21" to "0.50")
	// ------------------------------------------------------------------------
	amountBTC := "0.21"

	// Step 1: Ask Bitcoin for the current block height
	height := askBitcoin("getblockcount")
	fmt.Printf("\n[1] Live Blockchain Height : Block #%s\n", height)

	// Step 2: Check our miner wallet balance
	minerBalance := askBitcoin("-rpcwallet=kisumu_miner", "getbalance")
	fmt.Printf("[2] Miner Wallet Balance   : %s BTC\n", minerBalance)

	// Step 3: Create a brand-new native SegWit (bech32) receiving address
	newAddress := askBitcoin("-rpcwallet=kisumu_merchant", "getnewaddress", myProjectLabel, "bech32")
	fmt.Printf("[3] New Bitcoin Address    : %s (label: %s)\n", newAddress, myProjectLabel)

	// Step 4: Send real regtest Bitcoin to our new address
	txid := askBitcoin("-rpcwallet=kisumu_miner", "sendtoaddress", newAddress, amountBTC)
	fmt.Printf("[4] Sent %s BTC! TXID    : %s\n", amountBTC, txid)

	// Step 5: Check the waiting room (Mempool) before mining
	unconfirmed := askBitcoin("-rpcwallet=kisumu_merchant", "getunconfirmedbalance")
	fmt.Printf("[5] Waiting in Mempool     : %s BTC (unconfirmed)\n", unconfirmed)

	// Step 6: Mine 1 block so our transaction is permanently etched into the blockchain
	minerAddr := askBitcoin("-rpcwallet=kisumu_miner", "getnewaddress")
	askBitcoin("generatetoaddress", "1", minerAddr)
	newHeight := askBitcoin("getblockcount")
	merchantBalance := askBitcoin("-rpcwallet=kisumu_merchant", "getbalance")

	fmt.Printf("[6] Mined 1 Block! Height  : Block #%s\n", newHeight)
	fmt.Printf("[7] Merchant Confirmed Bal : %s BTC\n", merchantBalance)
	fmt.Println("====================================================")
	fmt.Println("SUCCESS! You just built and ran a real Bitcoin app.")
}
