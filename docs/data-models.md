# Ogul — Shared Data Models

These are the canonical data models used across `ogul-backend`, `ogul-ios`, and `ogul-web`. All services should treat these definitions as the source of truth.

---

## Scan

The core entity. Represents one facial scanning session.

```json
{
  "id": "scan_abc123",
  "userId": "user_1",
  "capturedAt": "2026-04-16T18:00:00Z",
  "status": "complete",
  "qualityScore": 0.91,
  "notes": "Day 3 post-op, some swelling on left cheek",
  "analytics": {
    "swellingPercent": 12.4,
    "asymmetryScore": 0.08
  },
  "createdAt": "2026-04-16T18:00:01Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique scan ID, prefix `scan_` |
| `userId` | string | Owning user ID |
| `capturedAt` | ISO 8601 | When the scan was captured on device |
| `status` | ScanStatus | Lifecycle state (see below) |
| `qualityScore` | float \| null | 0–1, set after processing (null before) |
| `notes` | string | Optional patient notes |
| `analytics` | Analytics \| null | Set after processing (null before) |
| `createdAt` | ISO 8601 | When the record was created on backend |

---

## ScanStatus

```
"created" | "uploaded" | "queued" | "processing" | "complete" | "failed"
```

---

## Analytics

Per-scan analytics object. Part of the `Scan` object, also returned independently.

```json
{
  "swellingPercent": 12.4,
  "asymmetryScore": 0.08
}
```

| Field | Type | Description |
|-------|------|-------------|
| `swellingPercent` | float | Estimated swelling relative to baseline (0 = none) |
| `asymmetryScore` | float | Left/right facial asymmetry score (0 = symmetric) |

---

## AnalyticsTrend

A data point in a trend series.

```json
{
  "capturedAt": "2026-04-16T18:00:00Z",
  "swellingPercent": 12.4,
  "asymmetryScore": 0.08
}
```

---

## UserAnalytics

Aggregate analytics for a user across all scans.

```json
{
  "userId": "user_1",
  "baselineScanId": "scan_xyz000",
  "latestScanId": "scan_abc123",
  "summary": {
    "totalScans": 7,
    "daysSinceBaseline": 3,
    "currentSwellingPercent": 12.4,
    "currentAsymmetryScore": 0.08,
    "peakSwellingPercent": 38.1,
    "swellingReductionPercent": 67.5
  },
  "trend": [
    { "capturedAt": "2026-04-13T08:00:00Z", "swellingPercent": 38.1, "asymmetryScore": 0.22 }
  ]
}
```

---

## User

```json
{
  "id": "user_1",
  "email": "patient@example.com",
  "displayName": "Alex Johnson",
  "createdAt": "2026-04-10T12:00:00Z"
}
```

---

## Type Mappings by Service

| Concept | Go (backend) | Swift (iOS) | TypeScript (web) |
|---------|-------------|-------------|-----------------|
| `Scan` | `models.Scan` | `Scan` struct | `Scan` interface |
| `Analytics` | `models.Analytics` | `ScanAnalytics` struct | `ScanAnalytics` interface |
| `ScanStatus` | `models.ScanStatus` (string) | `ScanStatus` enum | `ScanStatus` union type |
| `UserAnalytics` | `models.UserAnalytics` | `UserAnalytics` struct | `UserAnalytics` interface |
