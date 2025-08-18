package configs

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	App      AppConfig
	Database DatabaseConfig
	JWT      JWTConfig
	Redis    RedisConfig
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
	ConnMaxLifetime int // minutes
}

type JWTConfig struct {
	Secret          string
	AccessTokenTTL  int // hours
	RefreshTokenTTL int // hours
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

var GlobalConfig *Config

func LoadConfig() *Config {
	// Load .env if present; fall back to system env
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

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
			Username:        getEnv("DB_USERNAME", "root"), // << สำคัญ: ต้องตรงกับ .env
			Password:        getEnv("DB_PASSWORD", ""),
			DatabaseName:    getEnv("DB_NAME", "capstone_core"),
			SSLMode:         getEnv("DB_SSLMODE", "disable"),
			MaxOpenConns:    getEnvAsInt("DB_MAX_OPEN_CONNS", 25),
			MaxIdleConns:    getEnvAsInt("DB_MAX_IDLE_CONNS", 5),
			ConnMaxLifetime: getEnvAsInt("DB_CONN_MAX_LIFETIME", 300), // minutes
		},
		JWT: JWTConfig{
			Secret:          getEnv("JWT_SECRET", "your-super-secret-jwt-key"),
			AccessTokenTTL:  getEnvAsInt("JWT_ACCESS_TOKEN_TTL", 24),
			RefreshTokenTTL: getEnvAsInt("JWT_REFRESH_TOKEN_TTL", 168),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
	}

	GlobalConfig = config
	return config
}

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
