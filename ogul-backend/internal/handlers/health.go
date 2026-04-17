package handlers

import (
	"net/http"
	"time"
)

type healthResponse struct {
	Status    string    `json:"status"`
	Version   string    `json:"version"`
	Timestamp time.Time `json:"timestamp"`
}

func Health(w http.ResponseWriter, r *http.Request) {
	respond(w, http.StatusOK, healthResponse{
		Status:    "ok",
		Version:   "0.1.0",
		Timestamp: time.Now().UTC(),
	})
}
