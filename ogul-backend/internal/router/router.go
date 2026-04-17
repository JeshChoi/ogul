package router

import (
	"net/http"

	"github.com/ogul/backend/internal/handlers"
	"github.com/ogul/backend/internal/middleware"
)

// New returns the top-level HTTP handler with all routes registered.
// Uses Go 1.22+ ServeMux with method-pattern routing.
func New() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", handlers.Health)

	mux.HandleFunc("POST /scans", handlers.CreateScan)
	mux.HandleFunc("GET /scans/{id}", handlers.GetScan)

	mux.HandleFunc("GET /users/{id}/scans", handlers.GetUserScans)
	mux.HandleFunc("GET /users/{id}/analytics", handlers.GetUserAnalytics)

	return middleware.Logger(middleware.CORS(mux))
}
