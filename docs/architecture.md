# Ogul — System Architecture

## Overview

Ogul is a multi-service system for longitudinal facial change tracking. Users perform guided 3D facial scans on iPhone, upload scan data, and receive quantitative analytics on how their face changes over time — volume, asymmetry, and surface displacement.

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                         │
│                                                             │
│   ┌─────────────────┐          ┌──────────────────────┐    │
│   │   ogul-ios      │          │     ogul-web          │    │
│   │  SwiftUI app    │          │  Next.js dashboard    │    │
│   │  ARKit capture  │          │  analytics viewer     │    │
│   └────────┬────────┘          └──────────┬───────────┘    │
└────────────┼──────────────────────────────┼────────────────┘
             │ HTTPS / REST                 │ HTTPS / REST
             ▼                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       BACKEND LAYER                         │
│                                                             │
│   ┌──────────────────────────────────────────────────┐     │
│   │                  ogul-backend                    │     │
│   │                                                  │     │
│   │   ┌──────────┐  ┌────────────┐  ┌────────────┐  │     │
│   │   │   API    │  │  Ingestion │  │  Analytics │  │     │
│   │   │  Router  │→ │  Service   │→ │  Service   │  │     │
│   │   └──────────┘  └─────┬──────┘  └────────────┘  │     │
│   └─────────────────────── │ ───────────────────────┘     │
└────────────────────────────┼────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                       STORAGE LAYER                         │
│                                                             │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│   │  PostgreSQL  │   │  Object      │   │  (future)    │  │
│   │  scan meta   │   │  Storage     │   │  Redis cache │  │
│   │  analytics   │   │  mesh files  │   │              │  │
│   └──────────────┘   └──────────────┘   └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Services

### `ogul-ios` — Capture Client

**Responsibilities**
- Guided facial scan flow using ARKit + TrueDepth camera
- Pose consistency enforcement across sessions
- Local scan caching before upload
- Upload to backend via REST
- Displays scan history and analytics returned from backend

**Key Screens**
- `OnboardingView` — first-run setup, permissions
- `HomeView` — dashboard, last scan summary, CTA
- `ScanFlowView` — guided capture session (ARKit placeholder)
- `ScanHistoryView` — list of past scans with status
- `AnalyticsSummaryView` — swelling %, asymmetry score, trend chart

**Tech Stack**
- Swift / SwiftUI
- ARKit + TrueDepth (Phase 2+)
- URLSession for API communication

---

### `ogul-backend` — API + Processing Pipeline

**Responsibilities**
- REST API for scan ingestion, retrieval, and analytics
- Upload handling (signed URL generation or direct upload)
- Scan lifecycle management (uploaded → processing → complete)
- Analytics computation (Phase 2+: geometric comparison)
- Processing pipeline hooks for future ML integration

**API Surface (v1)**
```
GET  /health
POST /scans
GET  /scans/:id
GET  /users/:id/scans
GET  /users/:id/analytics
```

**Internal Package Structure**
```
cmd/api/          → entrypoint
internal/
  handlers/       → HTTP handlers per resource
  models/         → domain types (Scan, User, Analytics)
  middleware/     → logging, auth, CORS
  router/         → route registration
  store/          → database interface (future)
  pipeline/       → processing hooks (future)
```

**Tech Stack**
- Go (1.22+)
- Standard library HTTP server
- PostgreSQL (Phase 2+)
- Object storage for mesh files (Phase 2+)

**Why Go?**
Go was chosen over Node/TypeScript for this service because:
- Statically compiled, single binary deploys cleanly
- Strong concurrency model for parallel scan processing
- Excellent standard library for HTTP, JSON, and I/O
- Low memory footprint for a data-intensive pipeline
- Common in infrastructure/backend roles — signals strong engineering judgment

---

### `ogul-web` — Dashboard + Analytics Viewer

**Responsibilities**
- Landing page explaining the product
- Authenticated dashboard showing a user's scan history
- Scan timeline with delta visualization
- Analytics charts for swelling and asymmetry trends

**Pages**
- `/` — landing page
- `/dashboard` — user's scan overview + summary cards
- `/scans` — full scan timeline

**Tech Stack**
- Next.js 14+ (App Router)
- TypeScript
- Tailwind CSS
- Recharts (analytics charts, Phase 2+)

---

## Data Flow

### Scan Submission
```
iOS App
  → captures depth + RGB frame
  → stores locally as .obj / .usdz (Phase 2+)
  → POST /scans  { userId, capturedAt, notes }
  → receives scan_id + upload_url
  → uploads mesh file to object storage
  → PATCH /scans/:id { status: "uploaded" }

Backend
  → writes scan metadata to PostgreSQL
  → returns signed upload URL
  → (Phase 2+) triggers processing pipeline
```

### Analytics Retrieval
```
iOS App / Web
  → GET /users/:id/analytics

Backend
  → queries analytics table for user
  → (Phase 2+) computes diff against baseline scan
  → returns swellingPercent, asymmetryScore, trend series
```

---

## Scan Lifecycle

```
created → uploaded → queued → processing → complete
                                         → failed
```

| Status       | Description                                  |
|--------------|----------------------------------------------|
| `created`    | Record exists, no data uploaded yet          |
| `uploaded`   | Mesh file received in object storage         |
| `queued`     | Waiting for processing pipeline slot         |
| `processing` | Active geometric analysis                    |
| `complete`   | Analytics available                          |
| `failed`     | Processing error, retry eligible             |

---

## Security Considerations (Phase 2+)

- JWT-based auth on all non-health endpoints
- Signed URLs for object storage (time-limited)
- HIPAA-conscious data handling (PHI minimization)
- Audit log for all scan access

---

## Phase Boundaries

| Phase | Scope |
|-------|-------|
| Phase 1 | Scaffold, structure, mocked data, API skeleton |
| Phase 2 | Real upload + storage, auth, PostgreSQL |
| Phase 3 | ARKit TrueDepth capture, mesh upload |
| Phase 4 | Geometric processing, analytics computation |
| Phase 5 | Clinician view, multi-patient, reporting |
