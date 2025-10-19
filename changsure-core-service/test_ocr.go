package main

import (
	"fmt"
	"os"

	"github.com/otiai10/gosseract/v2"
)

func main() {
	// 🆕 Set environment variable
	os.Setenv("TESSDATA_PREFIX", "C:/Program Files/Tesseract-OCR/tessdata")
	
	// อ่านไฟล์
	imageData, err := os.ReadFile("idcard.jpg")
	if err != nil {
		panic(err)
	}

	client := gosseract.NewClient()
	defer client.Close()

	fmt.Printf("Image size: %d bytes\n", len(imageData))
	fmt.Printf("TESSDATA_PREFIX: %s\n\n", os.Getenv("TESSDATA_PREFIX"))

	// Test 1
	fmt.Println("=== Test 1: eng + PSM_AUTO ===")
	client.SetLanguage("eng")
	client.SetPageSegMode(gosseract.PSM_AUTO)

	err = client.SetImageFromBytes(imageData)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	text, err := client.Text()
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		return
	}

	fmt.Printf("Result: '%s'\n", text)
}