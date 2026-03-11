package payment

type OmiseWebhookEvent struct {
	Key  string `json:"key"`
	Data struct {
		ID       string                 `json:"id"`
		Amount   int64                  `json:"amount"`
		Metadata map[string]interface{} `json:"metadata"`
	} `json:"data"`
}

type OmiseChargeData struct {
	ID       string                 `json:"id"`
	Status   string                 `json:"status"`
	Amount   int64                  `json:"amount"`
	Currency string                 `json:"currency"`
	Metadata map[string]interface{} `json:"metadata"`
}
