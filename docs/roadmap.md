# Ogul — Product Roadmap

## Vision

> A "Fitbit for facial recovery" — guided repeated scans, longitudinal analytics, and objective measurement of how a face changes over time.

The system should eventually enable patients and clinicians to track post-surgical recovery with the same ease that a fitness tracker measures steps.

---

## Phase 1 — Foundation (Current)

**Goal:** Clean scaffold, shared data models, API skeleton, basic UI shells. No real data processing yet.

### Backend (`ogul-backend`)
- [x] Project structure with Go module
- [x] `/health` endpoint
- [x] `POST /scans` with mocked response
- [x] `GET /scans/:id` with mocked response
- [x] `GET /users/:id/scans` with mocked list
- [x] `GET /users/:id/analytics` with mocked analytics
- [ ] Request validation and structured error responses
- [ ] Structured logging middleware

### Web (`ogul-web`)
- [x] Next.js project with App Router + TypeScript
- [x] Landing page
- [x] Dashboard page with mocked scan cards
- [x] Scan timeline page
- [ ] Responsive mobile layout

### iOS (`ogul-ios`)
- [x] SwiftUI app structure
- [x] Onboarding screen
- [x] Home screen
- [x] Scan flow placeholder screen
- [x] Scan history screen
- [x] Analytics summary screen
- [x] APIService stub
- [x] Scan data model

### Docs
- [x] Architecture overview
- [x] Roadmap (this file)
- [x] API contract
- [x] Shared data models

---

## Phase 2 — Real Backend + Auth

**Goal:** Working upload, real persistence, authenticated API.

### Backend
- [ ] PostgreSQL schema + migrations
- [ ] Real `POST /scans` with DB write
- [ ] Object storage integration (S3 / GCS) for mesh files
- [ ] Signed URL generation for upload
- [ ] JWT auth middleware
- [ ] `PATCH /scans/:id` for status updates
- [ ] Unit tests for handlers

### Web
- [ ] Auth flow (login / signup)
- [ ] API integration (replace mock data)
- [ ] Protected dashboard routes

### iOS
- [ ] Auth flow (email or Sign in with Apple)
- [ ] Real `POST /scans` from app
- [ ] Upload mesh placeholder file to signed URL
- [ ] Scan history from real API

---

## Phase 3 — ARKit Capture

**Goal:** Real 3D facial capture from iPhone TrueDepth camera.

### iOS
- [ ] ARKit face tracking session
- [ ] TrueDepth depth data capture
- [ ] Pose consistency guide overlay (face alignment reticle)
- [ ] Consistent scan framing across sessions
- [ ] Export captured data as mesh or point cloud
- [ ] Upload to backend via signed URL

### Backend
- [ ] Validate mesh upload (format, size)
- [ ] Store mesh metadata (vertex count, capture quality)
- [ ] Trigger processing pipeline on upload complete

---

## Phase 4 — Processing Pipeline + Analytics

**Goal:** Compute geometric differences across scans and produce analytics.

### Backend Pipeline
- [ ] Mesh preprocessing (cleaning, decimation)
- [ ] Pose normalization (align to canonical orientation)
- [ ] Facial landmark detection
- [ ] Baseline scan selection per user
- [ ] Point-cloud / mesh delta computation
- [ ] Volume change calculation (swelling %)
- [ ] Left/right asymmetry score
- [ ] Surface displacement heatmap generation

### Web + iOS
- [ ] Real analytics from backend
- [ ] Swelling trend chart (time series)
- [ ] Asymmetry trend chart
- [ ] Heatmap visualization overlay
- [ ] Day-over-day comparison view

---

## Phase 5 — Clinical Features

**Goal:** Multi-patient support, clinician dashboard, exportable reports.

- [ ] Clinician role with multi-patient view
- [ ] Patient sharing / invitation flow
- [ ] PDF report export per patient
- [ ] Clinical note attachment per scan
- [ ] Alert thresholds (e.g., unexpected asymmetry increase)
- [ ] HIPAA compliance review

---

## Technical Debt & Infrastructure (Ongoing)

- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Docker + docker-compose for local dev
- [ ] Environment-based config management
- [ ] API versioning (`/v1/...`)
- [ ] Rate limiting
- [ ] Monitoring + alerting (Prometheus / Grafana or equivalent)
- [ ] End-to-end test suite

---

## Non-Goals (for now)

- Real-time or video-based tracking
- Non-facial body parts
- On-device ML processing
- Multi-language / i18n
