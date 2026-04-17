package main

import (
	"log/slog"
	"net/http"
	"os"

	"github.com/ogul/backend/internal/router"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	slog.Info("starting ogul-backend", "port", port)

	r := router.New()
	if err := http.ListenAndServe(":"+port, r); err != nil {
		slog.Error("server error", "err", err)
		os.Exit(1)
	}
}
