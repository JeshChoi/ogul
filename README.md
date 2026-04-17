# Ogul

A system for tracking facial changes over time using iPhone-based 3D capture and a backend processing pipeline.

The primary use case is **post-surgical facial swelling tracking** — guided repeated scans, objective geometric analytics, and longitudinal trend visualization.

> Existing systems measure faces at a single point in time. Ogul measures how faces change over time.

---

## Repository Structure

```
ogul/
├── ogul-ios/          iOS app — guided capture, scan history, analytics
├── ogul-backend/      Go API — scan ingestion, processing pipeline, analytics
├── ogul-web/          Next.js dashboard — landing page, analytics viewer
└── docs/
    ├── architecture.md   System architecture and data flow
    ├── roadmap.md        Phased development plan
    ├── api-contract.md   REST API specification
    └── data-models.md    Canonical shared data types
```

---

## System Overview

```
iPhone (SwiftUI + ARKit)
  ↓ POST /scans
Go Backend (ogul-backend)
  ↓ stores metadata + mesh
Processing Pipeline
  ↓ aligns scans, computes geometry
Analytics Service
  ↓ returns swelling %, asymmetry score, trend
Next.js Dashboard (ogul-web)
```

See [`docs/architecture.md`](docs/architecture.md) for the full diagram.

---

## Services

### `ogul-ios` — Capture Client
- SwiftUI app with 5 screens: onboarding, home, scan flow, history, analytics
- API service stub wired to `ogul-backend`
- ARKit TrueDepth integration in Phase 3

```bash
# See ogul-ios/README.md for Xcode setup instructions
```

### `ogul-backend` — API Server
- Go 1.22+, stdlib only (no frameworks)
- REST endpoints for scan lifecycle and analytics
- Mocked responses in Phase 1; PostgreSQL in Phase 2

```bash
cd ogul-backend
make run        # starts on :8080
```

### `ogul-web` — Dashboard
- Next.js 14 App Router, TypeScript, Tailwind CSS
- Landing page, recovery dashboard, scan timeline
- Mocked data in Phase 1; live API in Phase 2

```bash
cd ogul-web
npm install
cp .env.example .env.local
npm run dev     # starts on :3000
```

---

## API (Phase 1)

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Service health |
| `POST` | `/scans` | Create scan record |
| `GET` | `/scans/:id` | Get scan by ID |
| `GET` | `/users/:id/scans` | User's scan list |
| `GET` | `/users/:id/analytics` | Aggregate analytics + trend |

Full spec: [`docs/api-contract.md`](docs/api-contract.md)

---

## Core Data Model

```json
{
  "id": "scan_abc123",
  "userId": "user_1",
  "capturedAt": "2026-04-16T18:00:00Z",
  "status": "complete",
  "qualityScore": 0.91,
  "notes": "Day 3 post-op",
  "analytics": {
    "swellingPercent": 12.4,
    "asymmetryScore": 0.08
  }
}
```

Full model definitions: [`docs/data-models.md`](docs/data-models.md)

---

## Roadmap

| Phase | Scope |
|-------|-------|
| **1** (current) | Scaffold — API skeleton, SwiftUI screens, web UI, mocked data |
| **2** | Real persistence (PostgreSQL), auth, upload pipeline |
| **3** | ARKit TrueDepth capture, mesh file ingestion |
| **4** | Geometric processing, analytics computation |
| **5** | Clinical features, multi-patient, reporting |

Full roadmap: [`docs/roadmap.md`](docs/roadmap.md)

## To Get Started 
```# Backend (Go 1.22+)
cd ogul-backend && make run

# Web
cd ogul-web && npm install && cp .env.example .env.local && npm run dev

# iOS: create Xcode project, add OgulApp/ files — see ogul-ios/README.md```