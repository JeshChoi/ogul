package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/ogul/backend/internal/models"
)

// CreateScan handles POST /scans.
// Phase 1: validates the request and returns a mocked scan record.
func CreateScan(w http.ResponseWriter, r *http.Request) {
	var req models.CreateScanRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "request body could not be parsed")
		return
	}

	if req.UserID == "" {
		respondError(w, http.StatusBadRequest, "missing_user_id", "userId is required")
		return
	}
	if req.CapturedAt.IsZero() {
		respondError(w, http.StatusBadRequest, "missing_captured_at", "capturedAt is required")
		return
	}

	uploadURL := "https://storage.ogul.app/uploads/scan_mock?token=placeholder"
	scan := &models.Scan{
		ID:        "scan_mock001",
		UserID:    req.UserID,
		CapturedAt: req.CapturedAt,
		Status:    models.ScanStatusCreated,
		Notes:     req.Notes,
		UploadURL: &uploadURL,
		Analytics: nil,
		CreatedAt: time.Now().UTC(),
	}

	respond(w, http.StatusCreated, scan)
}

// GetScan handles GET /scans/{id}.
func GetScan(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if id == "" {
		respondError(w, http.StatusBadRequest, "missing_id", "scan id is required")
		return
	}

	// Phase 1: return mock data.
	score := 0.91
	scan := mockScan(id, "user_1", &score)
	respond(w, http.StatusOK, scan)
}

// --- mock helpers (replaced by real store in Phase 2) ---

func mockScan(id, userID string, qualityScore *float64) *models.Scan {
	capturedAt, _ := time.Parse(time.RFC3339, "2026-04-16T18:00:00Z")
	return &models.Scan{
		ID:           id,
		UserID:       userID,
		CapturedAt:   capturedAt,
		Status:       models.ScanStatusComplete,
		QualityScore: qualityScore,
		Notes:        "Day 3 post-op",
		Analytics: &models.Analytics{
			SwellingPercent: 12.4,
			AsymmetryScore:  0.08,
		},
		CreatedAt: capturedAt.Add(time.Second),
	}
}
