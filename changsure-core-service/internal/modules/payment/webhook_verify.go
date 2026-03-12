package payment

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"log"
)

func VerifyOmiseSignature(payload []byte, signature string, secret string) bool {
    mac1 := hmac.New(sha256.New, []byte(secret))
    mac1.Write(payload)
    sig1 := hex.EncodeToString(mac1.Sum(nil))
    
    secretBytes, err := base64.StdEncoding.DecodeString(secret)
    sig2 := "n/a"
    if err == nil {
        mac2 := hmac.New(sha256.New, secretBytes)
        mac2.Write(payload)
        sig2 = hex.EncodeToString(mac2.Sum(nil))
    }
    
    log.Printf("🔑 sig_raw:     %s", sig1)
    log.Printf("🔑 sig_decoded: %s", sig2)
    log.Printf("🔑 omise_sent:  %s", signature)
    
    if hmac.Equal([]byte(sig1), []byte(signature)) { return true }
    if err == nil && hmac.Equal([]byte(sig2), []byte(signature)) { return true }
    return false
}