package payment

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"log"
	"strings"
)

func VerifyOmiseSignature(payload []byte, signature string, secret string) bool {
    if signature == "" || secret == "" {
        return false
    }

    // ตัด prefix "test " ออก (กรณียิงจาก Postman)
    actualSignature := signature
    parts := strings.SplitN(signature, " ", 2)
    if len(parts) == 2 {
        actualSignature = parts[1]
    }

    // Decode Base64 secret ก่อน (Omise Dashboard ใช้แบบนี้)
    secretBytes, err := base64.StdEncoding.DecodeString(secret)
    if err != nil {
        log.Printf("❌ Failed to decode secret: %v", err)
        return false
    }

    mac := hmac.New(sha256.New, secretBytes)
    mac.Write(payload)
    expected := hex.EncodeToString(mac.Sum(nil))

    if hmac.Equal([]byte(expected), []byte(actualSignature)) {
        log.Printf("✅ Signature verified")
        return true
    }

    log.Printf("❌ Signature mismatch\n   Expected: %s\n   Got:      %s", expected[:20], actualSignature[:20])
    return false
}