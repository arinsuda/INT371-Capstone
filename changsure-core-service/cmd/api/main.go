package main

import (
	"context"
	"log"
	"time"

	"changsure-core-service/configs"
	"changsure-core-service/pkg/database"
	"changsure-core-service/pkg/storage"
)

func main() {

	cfg := configs.LoadConfig()

	if err := cfg.ValidateDatabaseConfig(); err != nil {
		log.Fatalf("invalid database config: %v", err)
	}

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}

	if err := database.RunMigrations(db); err != nil {
		log.Fatalf("failed to run migrations: %v", err)
	}

	store, err := storage.NewMinioStorage(storage.MinioOptions{
		Endpoint:  cfg.Minio.Endpoint,
		AccessKey: cfg.Minio.AccessKey,
		SecretKey: cfg.Minio.SecretKey,
		UseSSL:    cfg.Minio.UseSSL,
		Region:    cfg.Minio.Region,
		Bucket:    cfg.Minio.Bucket,
	})
	if err != nil {
		log.Fatalf("failed to init minio: %v", err)
	}

	if _, err := store.PresignPut(context.Background(), "healthz/.probe", "text/plain", 10*time.Second); err != nil {
		log.Printf("⚠️  minio presign test failed (bucket missing or acl?): %v", err)
	} else {
		log.Printf("✅ MinIO ready: bucket=%s endpoint=%s", cfg.Minio.Bucket, cfg.Minio.Endpoint)
	}

	log.Printf("✅ boot ok: env=%s port=%s db=%s", cfg.App.Environment, cfg.App.Port, cfg.Database.DatabaseName)

}
