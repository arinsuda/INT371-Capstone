package infra

import (
	"bytes"
	"encoding/json"
	"fmt"
	"mime/multipart"
	"net/http"
	"time"
)

type OCRClient interface {
	Scan(imageBytes []byte, filename string) (*OCRResult, error)
}

type ocrClient struct {
	baseURL string
	client  *http.Client
}

func NewOCRClient(baseURL string) OCRClient {
	return &ocrClient{
		baseURL: baseURL,
		client:  &http.Client{Timeout: 60 * time.Second},
	}
}

type OCRResult struct {
	Count int `json:"count"`
	Items []struct {
		Text       string      `json:"text"`
		Confidence float64     `json:"confidence"`
		BBox       [][]float64 `json:"bbox"`
	} `json:"items"`
}

func (c *ocrClient) Scan(imageBytes []byte, filename string) (*OCRResult, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	part, err := writer.CreateFormFile("file", filename)
	if err != nil {
		return nil, err
	}
	if _, err := part.Write(imageBytes); err != nil {
		return nil, err
	}
	writer.Close()

	req, err := http.NewRequest("POST", c.baseURL+"/ocr", body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("ocr service error: %s", resp.Status)
	}

	var out OCRResult
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return &out, nil
}
