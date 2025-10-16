package configs

import (
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	App      AppConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Redis    RedisConfig
	Minio    MinioConfig
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

/* ===== MinIO & Upload Policy ===== */
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
}

var GlobalConfig *Config

func LoadConfig() *Config {

	err := godotenv.Load(".env")
	if err != nil {
		log.Printf("[WARN] No .env file found, using system environment variables: %v", err)
	} else {
		log.Println("[INFO] Loaded configuration from .env file successfully")
	}

	allowDocTypes := getEnvAsCSV("ALLOW_DOC_TYPES",
		"id_card,certificate,license,portfolio,insurance",
	)
	allowMIME := getEnvAsCSV("ALLOW_MIME",
		"application/pdf,image/jpeg,image/png",
	)

	config := &Config{
		App: AppConfig{
			Name:        getEnv("APP_NAME", "CAPSTONE-API"),
			Port:        getEnv("PORT", "8080"),
			Environment: getEnv("APP_ENV", "development"),
			Debug:       getEnvAsBool("APP_DEBUG", true),
		},
		Database: DatabaseConfig{
			Driver:          getEnv("DB_DRIVER", "mysql"),
			Host:            getEnv("DB_HOST", "localhost"),
			Port:            getEnv("DB_PORT", "3306"),
			Username:        getEnv("DB_USERNAME", "root"),
			Password:        getEnv("DB_PASSWORD", ""),
			DatabaseName:    getEnv("DB_NAME", "capstone_core"),
			SSLMode:         getEnv("DB_SSLMODE", "disable"),
			MaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS", 5),
			ConnMaxLifetime: getEnvAsInt("DB_CONN_MAX_LIFETIME", 300),
		},
		JWT: JWTConfig{
			Secret:          getEnv("JWT_SECRET", ""),
			AccessTokenTTL:  getEnvAsInt("JWT_ACCESS_TOKEN_TTL", 24),
			RefreshTokenTTL: getEnvAsInt("JWT_REFRESH_TOKEN_TTL", 168),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		Minio: MinioConfig{
			Endpoint:           getEnv("MINIO_ENDPOINT", "127.0.0.1:9000"),
			AccessKey:          getEnv("MINIO_ACCESS_KEY", "minioadmin"),
			SecretKey:          getEnv("MINIO_SECRET_KEY", "minioadmin123"),
			UseSSL:             getEnvAsBool("MINIO_USE_SSL", false),
			Region:             getEnv("MINIO_REGION", ""),
			Bucket:             getEnv("MINIO_BUCKET", "oneplatform"),
			PresignUploadTTL:   getEnvAsInt("PRESIGN_UPLOAD_TTL", 900),
			PresignDownloadTTL: getEnvAsInt("PRESIGN_DOWNLOAD_TTL", 600),
			MaxFileMB:          getEnvAsInt("MAX_FILE_MB", 50),
			AllowDocTypes:      allowDocTypes,
			AllowMIME:          allowMIME,
			AllowDocTypesSet:   sliceToSet(allowDocTypes),
			AllowMIMESet:       sliceToSet(allowMIME),
			EnableVirusScan:    getEnvAsBool("ENABLE_VIRUS_SCAN", false),
		},
	}

	if config.JWT.Secret == "" {
		log.Fatal("[ERROR] Missing JWT_SECRET in .env — cannot start server securely")
	}

	GlobalConfig = config
	return config
}

/* ========== helpers ========== */

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intValue, err := strconv.Atoi(value); err == nil {
			return intValue
		}
	}
	return defaultValue
}

func getEnvAsBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		if boolValue, err := strconv.ParseBool(value); err == nil {
			return boolValue
		}
	}
	return defaultValue
}

func getEnvAsCSV(key string, defaultCSV string) []string {
	raw := getEnv(key, defaultCSV)
	if strings.TrimSpace(raw) == "" {
		return nil
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func sliceToSet(items []string) map[string]struct{} {
	m := make(map[string]struct{}, len(items))
	for _, v := range items {
		if v = strings.TrimSpace(v); v != "" {
			m[v] = struct{}{}
		}
	}
	return m
}
