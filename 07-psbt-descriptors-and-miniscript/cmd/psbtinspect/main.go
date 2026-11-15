// psbtinspect runs YOUR ParsePSBT/NextRole on a PSBT you produced with bitcoin-cli,
// so you can compare your parser with `bitcoin-cli decodepsbt` and `analyzepsbt`.
//
//	go run ./cmd/psbtinspect "<base64 psbt>"
package main

import (
	"fmt"
	"os"

	psbtlab "github.com/altradits/bitcoin-core-lab/07-psbt-descriptors-and-miniscript"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "usage: go run ./cmd/psbtinspect <base64-psbt>")
		os.Exit(2)
	}
	s, err := psbtlab.ParsePSBT(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, "ParsePSBT error:", err)
		os.Exit(1)
	}
	fmt.Printf("tx version %d, %d input(s), %d output(s), locktime %d\n", s.TxVersion, s.NumInputs, s.NumOutputs, s.LockTime)
	for i, in := range s.Inputs {
		fmt.Printf("  input %d: %+v\n", i, in)
	}
	for i, out := range s.Outputs {
		fmt.Printf("  output %d: %+v\n", i, out)
	}
	fmt.Println("next role (your NextRole):", psbtlab.NextRole(s))
	fmt.Println("Now compare with: bitcoin-cli -regtest analyzepsbt <psbt>  (field \"next\")")
}
