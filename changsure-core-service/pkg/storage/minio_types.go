package storage

// ==============================
// Minio Option Structs
// ==============================

type MinioOptions struct {
	Endpoint     string
	AccessKey    string
	SecretKey    string
	UseSSL       bool
	Region       string
	Bucket       string
	PublicBaseURL string
}

type MinioStorage struct {
	client *minio.Client
	bucket string
	cfg    *config.MinioConfig
}