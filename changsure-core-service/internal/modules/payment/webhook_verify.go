package payment

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"log"
)

func VerifyOmiseSignature(
	payload []byte,
	signature string,
	secret string,
) bool {

	if signature == "" || secret == "" {
		log.Printf("❌ Empty signature or secret")
		return false
	}

	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write(payload)
	expectedMAC := mac.Sum(nil)

	expectedSignature := hex.EncodeToString(expectedMAC)

	match := hmac.Equal(
		[]byte(expectedSignature),
		[]byte(signature),
	)

	if !match {
		log.Printf("❌ Signature mismatch")
		log.Printf("   Expected: %s...", expectedSignature[:20])
		log.Printf("   Got:      %s...", signature[:20])
	} else {
		log.Printf("✅ Signature verified")
	}

	return match
}
