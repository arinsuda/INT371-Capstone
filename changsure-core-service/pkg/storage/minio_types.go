package storage

type MinioOptions struct {
	Endpoint      string
	AccessKey     string
	SecretKey     string
	UseSSL        bool
	Region        string
	Bucket        string
	PublicBaseURL string
}

type ObjectStat struct {
	Size     int64
	ETag     string
	MIMEType string
}
