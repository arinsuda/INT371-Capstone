package infra

import (
	"sync"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
)

// cacheEntry entry ใน cache
type cacheEntry struct {
	result    *provider.OCRResult
	expiresAt time.Time
}

// MemoryCache implements CacheManager interface
type MemoryCache struct {
	cache map[string]*cacheEntry
	mu    sync.RWMutex
}

func NewMemoryCache() provider.CacheManager {
	cache := &MemoryCache{
		cache: make(map[string]*cacheEntry),
	}

	// Cleanup goroutine
	go cache.cleanupExpired()

	return cache
}

// Get ดึงข้อมูลจาก cache
func (c *MemoryCache) Get(key *provider.CacheKey) (*provider.OCRResult, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	cacheKey := c.buildKey(key)
	entry, exists := c.cache[cacheKey]

	if !exists {
		return nil, false
	}

	// ตรวจสอบว่าหมดอายุหรือไม่
	if time.Now().After(entry.expiresAt) {
		return nil, false
	}

	return entry.result, true
}

// Set บันทึกข้อมูลลง cache
func (c *MemoryCache) Set(key *provider.CacheKey, result *provider.OCRResult, ttl time.Duration) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	cacheKey := c.buildKey(key)
	c.cache[cacheKey] = &cacheEntry{
		result:    result,
		expiresAt: time.Now().Add(ttl),
	}

	return nil
}

// Clear ล้าง cache ทั้งหมด
func (c *MemoryCache) Clear() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.cache = make(map[string]*cacheEntry)
	return nil
}

// buildKey สร้าง key string จาก CacheKey
func (c *MemoryCache) buildKey(key *provider.CacheKey) string {
	return key.ImageHash + ":" + key.Strategy + ":" + key.Language
}

// cleanupExpired ลบ entries ที่หมดอายุ
func (c *MemoryCache) cleanupExpired() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		c.mu.Lock()
		now := time.Now()
		for key, entry := range c.cache {
			if now.After(entry.expiresAt) {
				delete(c.cache, key)
			}
		}
		c.mu.Unlock()
	}
}