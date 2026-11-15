// Stage 11 — YOUR WORKING FILE. `./lab.sh blank 11` copies this skeleton to ../sovereign_wallet_builder.go.
// Write every body, then `./lab.sh check 11`. The reference is ../solutions/ (spoiler: open only after
// the tests pass or after 3 honest attempts).
package main

import "fmt"

// NetworkProfile describes one of the four networks Bitcoin Core runs on.
type NetworkProfile struct {
	Name        string
	CLIFlag     string // "-regtest", "-signet", "-testnet4", or "(none)" for mainnet
	Bech32HRP   string // the human-readable part INCLUDING the separator '1', e.g. "bc1"
	DefaultPort int    // P2P port
	RPCPort     int    // default RPC port
	Purpose     string
}

// AllBitcoinNetworks returns regtest, signet, testnet4 and mainnet, IN THAT ORDER (your graduation ladder).
// Do not guess the ports: read src/chainparamsbase.cpp (RPC ports) and nDefaultPort in
// src/kernel/chainparams.cpp (P2P ports); read bech32_hrp in the same file.
func AllBitcoinNetworks() []NetworkProfile {
	// TODO
	return nil
}

// EstimateTxVBytes returns ceil(overhead + inputs*in_vB + outputs*out_vB) for single-key spends of one type.
// scriptType: "p2pkh"/"legacy", "p2wpkh"/"segwit"/"bc1q", "p2tr"/"taproot"/"bc1p"; anything else -> treat as p2wpkh.
// Derive every number yourself from the byte layout you learned in Stage 02 (write the derivation in your
// journal): overhead is 10 vB for legacy and 10.5 vB when the tx has a witness (marker+flag = 2 WU = 0.5 vB);
// a P2PKH input with a 72-byte DER sig and 33-byte key is 148 bytes; P2WPKH input 68 vB; P2TR key-path
// input 57.5 vB (64-byte Schnorr sig); outputs: P2PKH 34, P2WPKH 31, P2TR 43.
func EstimateTxVBytes(scriptType string, numInputs int, numOutputs int) int {
	// TODO
	return 0
}

func main() {
	for _, n := range AllBitcoinNetworks() {
		fmt.Printf("%-40s %-10s %-6s p2p=%d rpc=%d\n", n.Name, n.CLIFlag, n.Bech32HRP, n.DefaultPort, n.RPCPort)
	}
	fmt.Println("1-in/2-out: legacy", EstimateTxVBytes("legacy", 1, 2), "vB; segwit", EstimateTxVBytes("bc1q", 1, 2), "vB")
}
