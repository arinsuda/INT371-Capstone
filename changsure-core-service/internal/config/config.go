package config

import (
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

const (
	EnvDevelopment = "development"
	EnvProduction  = "production"
	EnvStaging     = "staging"
)

type Config struct {
	App      AppConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Redis    RedisConfig
	Minio    MinioConfig
	OCR      OCRConfig `mapstructure:"ocr"`
	Omise    OmiseConfig
}

type AppConfig struct {
	Name        string
	Port        string
	Environment string
	Debug       bool
}

type DatabaseConfig struct {
	Driver          string
	Host            string
	Port            string
	Username        string
	Password        string
	DatabaseName    string
	SSLMode         string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime int
}

type JWTConfig struct {
	Secret          string
	AccessTokenTTL  int
	RefreshTokenTTL int
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

type MinioConfig struct {
	Endpoint           string
	AccessKey          string
	SecretKey          string
	UseSSL             bool
	Region             string
	Bucket             string
	PresignUploadTTL   int
	PresignDownloadTTL int
	MaxFileMB          int
	AllowDocTypes      []string
	AllowMIME          []string

	AllowDocTypesSet map[string]struct{}
	AllowMIMESet     map[string]struct{}

	EnableVirusScan bool

	PublicBaseURL string
}

type OCRConfig struct {
	BaseURL string `mapstructure:"base_url" json:"base_url"`
}

type OmiseConfig struct {
	PublicKey     string
	SecretKey     string
	Currency      string
	Timeout       time.Duration
	WebhookSecret string
	QRExpiryMinutes int
}

var GlobalConfig *Config

func LoadConfig() *Config {
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("[WARN] No .env file found, using system environment variables: %v", err)
	} else {
		log.Println("[INFO] Loaded configuration from .env file successfully")
	}

	allowDocTypes := getEnvAsCSVOptional("ALLOW_DOC_TYPES")
	allowMIME := getEnvAsCSVOptional("ALLOW_MIME")

	cfg := &Config{
		App: AppConfig{
			Name:        getEnv("APP_NAME"),
			Port:        getEnv("PORT"),
			Environment: getEnv("APP_ENV"),
			Debug:       getEnvAsBool("APP_DEBUG"),
		},
		Database: DatabaseConfig{
			Driver:          getEnv("DB_DRIVER"),
			Host:            getEnv("DB_HOST"),
			Port:            getEnv("DB_PORT"),
			Username:        getEnv("DB_USERNAME"),
			Password:        getEnv("DB_PASSWORD"),
			DatabaseName:    getEnv("DB_NAME"),
			SSLMode:         getEnv("DB_SSLMODE"),
			MaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS"),
			MaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS"),
			ConnMaxLifetime: getEnvAsInt("DB_CONN_MAX_LIFETIME"),
		},
		JWT: JWTConfig{
			Secret:          getEnv("JWT_SECRET"),
			AccessTokenTTL:  getEnvAsInt("JWT_ACCESS_TOKEN_TTL"),
			RefreshTokenTTL: getEnvAsInt("JWT_REFRESH_TOKEN_TTL"),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST"),
			Port:     getEnv("REDIS_PORT"),
			Password: getEnv("REDIS_PASSWORD"),
			DB:       getEnvAsInt("REDIS_DB"),
		},
		Minio: MinioConfig{
			Endpoint:           getEnv("MINIO_ENDPOINT"),
			AccessKey:          getEnv("MINIO_ACCESS_KEY"),
			SecretKey:          getEnv("MINIO_SECRET_KEY"),
			UseSSL:             getEnvAsBool("MINIO_USE_SSL"),
			Region:             getEnv("MINIO_REGION"),
			Bucket:             getEnv("MINIO_BUCKET"),
			PresignUploadTTL:   getEnvAsInt("PRESIGN_UPLOAD_TTL"),
			PresignDownloadTTL: getEnvAsInt("PRESIGN_DOWNLOAD_TTL"),
			MaxFileMB:          getEnvAsInt("MAX_FILE_MB"),
			AllowDocTypes:      allowDocTypes,
			AllowMIME:          allowMIME,
			AllowDocTypesSet:   sliceToSet(allowDocTypes),
			AllowMIMESet:       sliceToSet(allowMIME),
			EnableVirusScan:    getEnvAsBool("ENABLE_VIRUS_SCAN"),
			PublicBaseURL:      os.Getenv("MINIO_PUBLIC_ENDPOINT"),
		},
		OCR: OCRConfig{
			BaseURL: getEnv("OCR_BASE_URL"),
		},
		Omise: OmiseConfig{
			PublicKey:       os.Getenv("OMISE_PUBLIC_KEY"),
			SecretKey:       os.Getenv("OMISE_SECRET_KEY"),
			Currency:        os.Getenv("OMISE_CURRENCY"),
			Timeout:         time.Duration(getEnvAsInt("OMISE_TIMEOUT_SECONDS")) * time.Second,
			WebhookSecret:   os.Getenv("OMISE_WEBHOOK_SECRET"),
			QRExpiryMinutes: getEnvAsInt("OMISE_QR_EXPIRY_MINUTES"),
		},
	}

	if strings.TrimSpace(cfg.JWT.Secret) == "" {
		log.Fatal("[ERROR] Missing JWT_SECRET — cannot start server securely")
	}

	GlobalConfig = cfg
	return cfg
}

func (c *Config) IsDevelopment() bool {
	return strings.EqualFold(c.App.Environment, EnvDevelopment)
}

func (c *Config) IsProduction() bool {
	return strings.EqualFold(c.App.Environment, EnvProduction)
}

func (c *Config) IsStaging() bool {
	return strings.EqualFold(c.App.Environment, EnvStaging)
}

func getEnv(key string) string {
	v, ok := os.LookupEnv(key)
	if !ok || strings.TrimSpace(v) == "" {
		log.Fatalf("missing required env %s", key)
	}
	return v
}

func getEnvAsInt(key string) int {
	raw := getEnv(key)
	n, err := strconv.Atoi(raw)
	if err != nil {
		log.Fatalf("invalid int for %s=%q", key, raw)
	}
	return n
}

func getEnvAsBool(key string) bool {
	raw := getEnv(key)
	b, err := strconv.ParseBool(raw)
	if err != nil {
		log.Fatalf("invalid bool for %s=%q (expected true/false/1/0)", key, raw)
	}
	return b
}

func getEnvAsCSVOptional(key string) []string {
	if v, ok := os.LookupEnv(key); ok && strings.TrimSpace(v) != "" {
		return splitCSV(v)
	}
	return nil
}

func getEnvAsCSVStrict(key string) []string {
	return splitCSV(getEnv(key))
}

func splitCSV(raw string) []string {
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if s := strings.TrimSpace(p); s != "" {
			out = append(out, s)
		}
	}
	return out
}

func sliceToSet(items []string) map[string]struct{} {
	if len(items) == 0 {
		return map[string]struct{}{}
	}
	m := make(map[string]struct{}, len(items))
	for _, v := range items {
		if s := strings.TrimSpace(v); s != "" {
			m[s] = struct{}{}
		}
	}
	return m
}
