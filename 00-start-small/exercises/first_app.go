package main

// ============================================================================
// YOUR FIRST BITCOIN PROGRAM — SKELETON (Stage 00, Micro-Step 4)
// ============================================================================
// Copy this file to my-work/00-start-small/first_app.go and replace every
// TODO(you). Do not open solutions/first_app.go until
// ./00-start-small/check_first_app.sh passes or you have tried 3 times.
//
// Run:   go run my-work/00-start-small/first_app.go
//
// The program must print (in any wording you like):
//   - the current block height
//   - the kisumu_miner balance
//   - a NEW address from kisumu_merchant (starts with bcrt1)
//   - the txid (64 hex characters) of a payment you send to that address
//   - the block height after you mine 1 block
// ============================================================================

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// cliCommand returns the CLI program and its fixed leading arguments.
// Environment plumbing only (given to you): it lets the checker point the
// program at your node, e.g. BTC_CLI="bitcoin-cli -datadir=$HOME/regtest-lab".
func cliCommand() (string, []string) {
	fields := strings.Fields(os.Getenv("BTC_CLI"))
	if len(fields) == 0 {
		return "bitcoin-cli", []string{"-regtest"}
	}
	return fields[0], fields[1:]
}

// askBitcoin runs one bitcoin-cli call and returns its trimmed output.
// If the command fails, return a string that starts with "Error:" and
// includes what the node said.
func askBitcoin(args ...string) string {
	name, base := cliCommand()
	_ = name
	_ = base
	_ = exec.Command // keeps the skeleton compiling; delete once you call os/exec for real
	// TODO(you): build the full argument list (base + args), run the command
	// with os/exec, and return the trimmed output (or an "Error: ..." string).
	return "Error: askBitcoin not written yet"
}

func main() {
	myProjectLabel := "TODO-your-name" // TODO(you): put your own label here
	amountBTC := "0.21"

	// TODO(you): 1. print the current block height

	// TODO(you): 2. print the kisumu_miner wallet balance

	// TODO(you): 3. get a new bech32 address from kisumu_merchant using myProjectLabel, print it

	// TODO(you): 4. send amountBTC from kisumu_miner to that address with an explicit
	//               fee rate (sat/vB), print the txid

	// TODO(you): 5. print how many transactions are in the mempool now

	// TODO(you): 6. mine 1 block to a kisumu_miner address, print the new height

	_ = myProjectLabel
	_ = amountBTC
	fmt.Println("TODO(you): finish main()")
	os.Exit(1)
}
