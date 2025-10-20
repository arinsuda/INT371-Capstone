package infra

import (
	"sync"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
)

type cacheEntry struct {
	result    *provider.OCRResult
	expiresAt time.Time
}

type MemoryCache struct {
	cache map[string]*cacheEntry
	mu    sync.RWMutex
}

func NewMemoryCache() provider.CacheManager {
	cache := &MemoryCache{
		cache: make(map[string]*cacheEntry),
	}

	go cache.cleanupExpired()

	return cache
}

func (c *MemoryCache) Get(key *provider.CacheKey) (*provider.OCRResult, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	cacheKey := c.buildKey(key)
	entry, exists := c.cache[cacheKey]

	if !exists {
		return nil, false
	}

	if time.Now().After(entry.expiresAt) {
		return nil, false
	}

	return entry.result, true
}

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

func (c *MemoryCache) Clear() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.cache = make(map[string]*cacheEntry)
	return nil
}

func (c *MemoryCache) buildKey(key *provider.CacheKey) string {
	return key.ImageHash + ":" + key.Strategy + ":" + key.Language
}

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
