package main

import (
	"testing"
)

func TestKESToSatsAndDustGuardrail(t *testing.T) {
	engine := NewBridgeEngine(11_500_000.0, "http://127.0.0.1:18443", "", "")

	sats, btc, err := engine.KESToSats(1150.0)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if sats != 10_000 || btc != "0.00010000" {
		t.Fatalf("expected 10000 sats (0.00010000 BTC), got %d (%s)", sats, btc)
	}

	// Verify P2WPKH dust threshold (< 546 sats) rejection
	_, _, err = engine.KESToSats(10.0) // ~87 sats < 546 dust limit
	if err == nil {
		t.Fatalf("expected dust threshold error for 10 KES (~87 sats), got nil")
	}
}

func TestDarajaWebhookIdempotency(t *testing.T) {
	engine := NewBridgeEngine(11_500_000.0, "http://127.0.0.1:18443", "", "")

	broadcastCount := 0
	mockNewAddr := func(label string) (string, error) {
		return "bcrt1qkisumupostestaddress000000000000000000", nil
	}
	mockSettle := func(addr, amountBTC string) (string, error) {
		broadcastCount++
		return "f4184fc596403b9d638783cf57adfe4c75c605f6356fbc91338530e9831e9e16", nil
	}

	cb := DarajaSTKCallback{
		MerchantRequestID: "29115-34620561-1",
		CheckoutRequestID: "ws_CO_17102026_KSM_IDEMPOTENT",
		ResultCode:        0,
		ResultDesc:        "Success",
		AmountKES:         2300.0,
		MpesaReceipt:      "QJH8KSM999",
		PhoneNumber:       "254712345678",
	}

	rec1, replayed1, err := engine.ProcessCallback(cb, mockSettle, mockNewAddr)
	if err != nil || replayed1 {
		t.Fatalf("expected first webhook to settle cleanly, err=%v replayed=%v", err, replayed1)
	}

	rec2, replayed2, err := engine.ProcessCallback(cb, mockSettle, mockNewAddr)
	if err != nil || !replayed2 {
		t.Fatalf("expected duplicate webhook to be flagged as replayed, err=%v replayed=%v", err, replayed2)
	}

	if broadcastCount != 1 {
		t.Fatalf("expected exactly 1 on-chain broadcast, got %d", broadcastCount)
	}
	if rec1.TxID != rec2.TxID {
		t.Fatalf("expected identical TxID across duplicate webhooks")
	}
}
