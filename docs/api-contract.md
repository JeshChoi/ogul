# Ogul — API Contract (v1)

Base URL: `https://api.ogul.app/v1` (local: `http://localhost:8080`)

All requests and responses use `application/json`. Timestamps are ISO 8601 UTC.

---

## Health

### `GET /health`

Returns service health status. No auth required.

**Response `200`**
```json
{
  "status": "ok",
  "version": "0.1.0",
  "timestamp": "2026-04-16T18:00:00Z"
}
```

---

## Scans

### `POST /scans`

Create a new scan record. Returns the scan ID and (future) a signed upload URL for the mesh file.

**Request Body**
```json
{
  "userId": "user_1",
  "capturedAt": "2026-04-16T18:00:00Z",
  "notes": "Day 3 post-op, minor swelling on left side"
}
```

**Response `201`**
```json
{
  "id": "scan_abc123",
  "userId": "user_1",
  "capturedAt": "2026-04-16T18:00:00Z",
  "status": "created",
  "qualityScore": null,
  "notes": "Day 3 post-op, minor swelling on left side",
  "uploadUrl": "https://storage.ogul.app/uploads/scan_abc123?token=...",
  "analytics": null,
  "createdAt": "2026-04-16T18:00:01Z"
}
```

**Error Responses**
| Code | Reason |
|------|--------|
| `400` | Missing required fields |
| `401` | Unauthorized (Phase 2+) |

---

### `GET /scans/:id`

Retrieve a single scan by ID.

**Response `200`**
```json
{
  "id": "scan_abc123",
  "userId": "user_1",
  "capturedAt": "2026-04-16T18:00:00Z",
  "status": "complete",
  "qualityScore": 0.91,
  "notes": "Day 3 post-op",
  "uploadUrl": null,
  "analytics": {
    "swellingPercent": 12.4,
    "asymmetryScore": 0.08
  },
  "createdAt": "2026-04-16T18:00:01Z"
}
```

**Error Responses**
| Code | Reason |
|------|--------|
| `404` | Scan not found |

---

## Users

### `GET /users/:id/scans`

Retrieve all scans for a user, ordered by `capturedAt` descending.

**Query Parameters**
| Param | Type | Description |
|-------|------|-------------|
| `limit` | int | Max results (default: 20, max: 100) |
| `offset` | int | Pagination offset |
| `status` | string | Filter by status |

**Response `200`**
```json
{
  "userId": "user_1",
  "total": 7,
  "scans": [
    {
      "id": "scan_abc123",
      "capturedAt": "2026-04-16T18:00:00Z",
      "status": "complete",
      "qualityScore": 0.91,
      "notes": "Day 3 post-op",
      "analytics": {
        "swellingPercent": 12.4,
        "asymmetryScore": 0.08
      }
    },
    {
      "id": "scan_xyz456",
      "capturedAt": "2026-04-14T09:30:00Z",
      "status": "complete",
      "qualityScore": 0.87,
      "notes": "Day 1 post-op",
      "analytics": {
        "swellingPercent": 31.2,
        "asymmetryScore": 0.19
      }
    }
  ]
}
```

---

### `GET /users/:id/analytics`

Retrieve aggregate analytics and trend data for a user across all scans.

**Response `200`**
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
    { "capturedAt": "2026-04-13T08:00:00Z", "swellingPercent": 38.1, "asymmetryScore": 0.22 },
    { "capturedAt": "2026-04-14T09:30:00Z", "swellingPercent": 31.2, "asymmetryScore": 0.19 },
    { "capturedAt": "2026-04-15T10:00:00Z", "swellingPercent": 21.5, "asymmetryScore": 0.14 },
    { "capturedAt": "2026-04-16T18:00:00Z", "swellingPercent": 12.4, "asymmetryScore": 0.08 }
  ]
}
```

---

## Error Schema

All error responses follow this shape:

```json
{
  "error": {
    "code": "scan_not_found",
    "message": "No scan found with id scan_abc123"
  }
}
```

---

## Scan Status Lifecycle

```
created → uploaded → queued → processing → complete
                                         → failed
```

---

## Versioning

This is `v1`. All endpoints will be prefixed `/v1/` in production. Breaking changes increment the major version.
