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

// BBox matches ocr-service response: {top_left, top_right, bottom_right, bottom_left}
type BBox struct {
	TopLeft     [2]float64 `json:"top_left"`
	TopRight    [2]float64 `json:"top_right"`
	BottomRight [2]float64 `json:"bottom_right"`
	BottomLeft  [2]float64 `json:"bottom_left"`
}

type OCRItem struct {
	Text       string  `json:"text"`
	Confidence float64 `json:"confidence"`
	BBox       BBox    `json:"bbox"`
}

type OCRResult struct {
	Count      int       `json:"count"`
	Items      []OCRItem `json:"items"`
	RequestID  string    `json:"request_id,omitempty"`
	ElapsedMs  float64   `json:"elapsed_ms,omitempty"`
}

func (c *ocrClient) Scan(imageBytes []byte, filename string) (*OCRResult, error) {
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	part, err := writer.CreateFormFile("file", filename)
	if err != nil {
		return nil, fmt.Errorf("create form file: %w", err)
	}
	if _, err := part.Write(imageBytes); err != nil {
		return nil, fmt.Errorf("write file bytes: %w", err)
	}
	writer.Close()

	req, err := http.NewRequest("POST", c.baseURL+"/ocr", body)
	if err != nil {
		return nil, fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("ocr request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		// Try to parse error body from ocr-service
		var errBody struct {
			Error   string `json:"error"`
			Message string `json:"message"`
		}
		_ = json.NewDecoder(resp.Body).Decode(&errBody)
		if errBody.Message != "" {
			return nil, fmt.Errorf("ocr service error [%s]: %s", errBody.Error, errBody.Message)
		}
		return nil, fmt.Errorf("ocr service error: %s", resp.Status)
	}

	var out OCRResult
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, fmt.Errorf("decode ocr response: %w", err)
	}
	return &out, nil
}