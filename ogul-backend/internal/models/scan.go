package models

import "time"

// ScanStatus represents the lifecycle state of a scan.
type ScanStatus string

const (
	ScanStatusCreated    ScanStatus = "created"
	ScanStatusUploaded   ScanStatus = "uploaded"
	ScanStatusQueued     ScanStatus = "queued"
	ScanStatusProcessing ScanStatus = "processing"
	ScanStatusComplete   ScanStatus = "complete"
	ScanStatusFailed     ScanStatus = "failed"
)

// Analytics holds per-scan computed metrics.
type Analytics struct {
	SwellingPercent  float64 `json:"swellingPercent"`
	AsymmetryScore   float64 `json:"asymmetryScore"`
}

// Scan is the core domain entity representing one facial scanning session.
type Scan struct {
	ID           string     `json:"id"`
	UserID       string     `json:"userId"`
	CapturedAt   time.Time  `json:"capturedAt"`
	Status       ScanStatus `json:"status"`
	QualityScore *float64   `json:"qualityScore"`
	Notes        string     `json:"notes"`
	UploadURL    *string    `json:"uploadUrl,omitempty"`
	Analytics    *Analytics `json:"analytics"`
	CreatedAt    time.Time  `json:"createdAt"`
}

// AnalyticsTrendPoint is a single data point in a user's trend series.
type AnalyticsTrendPoint struct {
	CapturedAt      time.Time `json:"capturedAt"`
	SwellingPercent float64   `json:"swellingPercent"`
	AsymmetryScore  float64   `json:"asymmetryScore"`
}

// AnalyticsSummary is the aggregate summary across all of a user's scans.
type AnalyticsSummary struct {
	TotalScans                int     `json:"totalScans"`
	DaysSinceBaseline         int     `json:"daysSinceBaseline"`
	CurrentSwellingPercent    float64 `json:"currentSwellingPercent"`
	CurrentAsymmetryScore     float64 `json:"currentAsymmetryScore"`
	PeakSwellingPercent       float64 `json:"peakSwellingPercent"`
	SwellingReductionPercent  float64 `json:"swellingReductionPercent"`
}

// UserAnalytics aggregates analytics data for a single user across time.
type UserAnalytics struct {
	UserID         string                `json:"userId"`
	BaselineScanID string                `json:"baselineScanId"`
	LatestScanID   string                `json:"latestScanId"`
	Summary        AnalyticsSummary      `json:"summary"`
	Trend          []AnalyticsTrendPoint `json:"trend"`
}

// CreateScanRequest is the payload for POST /scans.
type CreateScanRequest struct {
	UserID     string    `json:"userId"`
	CapturedAt time.Time `json:"capturedAt"`
	Notes      string    `json:"notes"`
}

// UserScansResponse wraps a paginated scan list.
type UserScansResponse struct {
	UserID string  `json:"userId"`
	Total  int     `json:"total"`
	Scans  []*Scan `json:"scans"`
}
