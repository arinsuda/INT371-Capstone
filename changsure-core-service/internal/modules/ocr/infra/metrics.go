package infra

import (
	"sync"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
)

type StrategyMetrics struct {
	Name              string
	TotalExecutions   int64
	SuccessCount      int64
	FailureCount      int64
	TotalDuration     time.Duration
	AverageDuration   time.Duration
	AverageConfidence float64
	ErrorsByType      map[string]int64
}

type MetricsCollector struct {
	strategies map[string]*StrategyMetrics
	mu         sync.RWMutex
}

func NewMetricsCollector() provider.MetricsCollector {
	return &MetricsCollector{
		strategies: make(map[string]*StrategyMetrics),
	}
}

func (m *MetricsCollector) RecordStrategyExecution(strategy string, duration time.Duration, success bool) {
	m.mu.Lock()
	defer m.mu.Unlock()

	metrics, exists := m.strategies[strategy]
	if !exists {
		metrics = &StrategyMetrics{
			Name:         strategy,
			ErrorsByType: make(map[string]int64),
		}
		m.strategies[strategy] = metrics
	}

	metrics.TotalExecutions++
	metrics.TotalDuration += duration

	if success {
		metrics.SuccessCount++
	} else {
		metrics.FailureCount++
	}

	if metrics.TotalExecutions > 0 {
		metrics.AverageDuration = metrics.TotalDuration / time.Duration(metrics.TotalExecutions)
	}
}

func (m *MetricsCollector) RecordOCRConfidence(strategy string, confidence float64) {
	m.mu.Lock()
	defer m.mu.Unlock()

	metrics, exists := m.strategies[strategy]
	if !exists {
		return
	}

	totalConfidence := metrics.AverageConfidence * float64(metrics.SuccessCount-1)
	metrics.AverageConfidence = (totalConfidence + confidence) / float64(metrics.SuccessCount)
}

func (m *MetricsCollector) RecordError(strategy string, errorType string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	metrics, exists := m.strategies[strategy]
	if !exists {
		return
	}

	metrics.ErrorsByType[errorType]++
}

func (m *MetricsCollector) GetMetrics() map[string]interface{} {
	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make(map[string]interface{})

	var totalExecutions int64
	var totalSuccess int64
	var totalFailures int64

	strategies := make([]map[string]interface{}, 0, len(m.strategies))

	for _, metrics := range m.strategies {
		totalExecutions += metrics.TotalExecutions
		totalSuccess += metrics.SuccessCount
		totalFailures += metrics.FailureCount

		strategyData := map[string]interface{}{
			"name":                metrics.Name,
			"total_executions":    metrics.TotalExecutions,
			"success_count":       metrics.SuccessCount,
			"failure_count":       metrics.FailureCount,
			"success_rate":        float64(metrics.SuccessCount) / float64(metrics.TotalExecutions),
			"average_duration_ms": metrics.AverageDuration.Milliseconds(),
			"average_confidence":  metrics.AverageConfidence,
			"errors_by_type":      metrics.ErrorsByType,
		}

		strategies = append(strategies, strategyData)
	}

	result["strategies"] = strategies
	result["total"] = map[string]interface{}{
		"total_executions": totalExecutions,
		"total_success":    totalSuccess,
		"total_failures":   totalFailures,
		"success_rate":     float64(totalSuccess) / float64(totalExecutions),
	}

	return result
}
