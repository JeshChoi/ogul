package handlers

import (
	"net/http"
	"time"

	"github.com/ogul/backend/internal/models"
)

// GetUserScans handles GET /users/{id}/scans.
func GetUserScans(w http.ResponseWriter, r *http.Request) {
	userID := r.PathValue("id")
	if userID == "" {
		respondError(w, http.StatusBadRequest, "missing_user_id", "user id is required")
		return
	}

	score1, score2 := 0.91, 0.87
	scans := []*models.Scan{
		mockScan("scan_abc123", userID, &score1),
		mockScan("scan_xyz456", userID, &score2),
	}

	respond(w, http.StatusOK, models.UserScansResponse{
		UserID: userID,
		Total:  len(scans),
		Scans:  scans,
	})
}

// GetUserAnalytics handles GET /users/{id}/analytics.
func GetUserAnalytics(w http.ResponseWriter, r *http.Request) {
	userID := r.PathValue("id")
	if userID == "" {
		respondError(w, http.StatusBadRequest, "missing_user_id", "user id is required")
		return
	}

	trend := []models.AnalyticsTrendPoint{
		{CapturedAt: parseTime("2026-04-13T08:00:00Z"), SwellingPercent: 38.1, AsymmetryScore: 0.22},
		{CapturedAt: parseTime("2026-04-14T09:30:00Z"), SwellingPercent: 31.2, AsymmetryScore: 0.19},
		{CapturedAt: parseTime("2026-04-15T10:00:00Z"), SwellingPercent: 21.5, AsymmetryScore: 0.14},
		{CapturedAt: parseTime("2026-04-16T18:00:00Z"), SwellingPercent: 12.4, AsymmetryScore: 0.08},
	}

	analytics := &models.UserAnalytics{
		UserID:         userID,
		BaselineScanID: "scan_xyz000",
		LatestScanID:   "scan_abc123",
		Summary: models.AnalyticsSummary{
			TotalScans:               7,
			DaysSinceBaseline:        3,
			CurrentSwellingPercent:   12.4,
			CurrentAsymmetryScore:    0.08,
			PeakSwellingPercent:      38.1,
			SwellingReductionPercent: 67.5,
		},
		Trend: trend,
	}

	respond(w, http.StatusOK, analytics)
}

func parseTime(s string) time.Time {
	t, _ := time.Parse(time.RFC3339, s)
	return t
}
