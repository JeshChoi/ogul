# ogul-backend

Backend API server for the Ogul facial tracking system.

Written in Go. Uses only the standard library in Phase 1.

---

## Project Structure

```
ogul-backend/
├── cmd/
│   └── api/
│       └── main.go          # Entrypoint
├── internal/
│   ├── handlers/
│   │   ├── health.go        # GET /health
│   │   ├── scans.go         # POST /scans, GET /scans/:id
│   │   ├── users.go         # GET /users/:id/scans, /analytics
│   │   └── respond.go       # JSON response helpers
│   ├── middleware/
│   │   ├── logger.go        # Request logging
│   │   └── cors.go          # CORS headers
│   ├── models/
│   │   ├── scan.go          # Scan, Analytics, UserAnalytics types
│   │   └── user.go          # User type
│   ├── router/
│   │   └── router.go        # Route registration
│   └── store/               # (Phase 2) DB interface
├── go.mod
└── Makefile
```

---

## Running Locally

**Requirements:** Go 1.22+

```bash
# Run the dev server
make run

# Or directly
go run ./cmd/api
```

Server starts on `http://localhost:8080` by default. Set `PORT` env var to override.

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Service health check |
| `POST` | `/scans` | Create a new scan record |
| `GET` | `/scans/:id` | Get scan by ID |
| `GET` | `/users/:id/scans` | Get all scans for a user |
| `GET` | `/users/:id/analytics` | Get aggregate analytics for a user |

See `docs/api-contract.md` for full request/response shapes.

---

## Development

```bash
# Run tests
make test

# Lint
make lint

# Build binary
make build
```

---

## Roadmap

- **Phase 1** (current): Mocked responses, no persistence
- **Phase 2**: PostgreSQL + real storage, auth middleware
- **Phase 3**: Processing pipeline hooks, mesh file ingestion
- **Phase 4**: Geometric analytics computation
