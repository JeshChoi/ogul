import type { Scan, UserAnalytics } from "@/types";

export const MOCK_SCANS: Scan[] = [
  {
    id: "scan_001",
    userId: "user_1",
    capturedAt: "2026-04-16T18:00:00Z",
    status: "complete",
    qualityScore: 0.91,
    notes: "Day 3 post-op, improving",
    analytics: { swellingPercent: 12.4, asymmetryScore: 0.08 },
    createdAt: "2026-04-16T18:00:01Z",
  },
  {
    id: "scan_002",
    userId: "user_1",
    capturedAt: "2026-04-15T10:00:00Z",
    status: "complete",
    qualityScore: 0.88,
    notes: "Day 2 post-op",
    analytics: { swellingPercent: 21.5, asymmetryScore: 0.14 },
    createdAt: "2026-04-15T10:00:01Z",
  },
  {
    id: "scan_003",
    userId: "user_1",
    capturedAt: "2026-04-14T09:30:00Z",
    status: "complete",
    qualityScore: 0.87,
    notes: "Day 1 post-op",
    analytics: { swellingPercent: 31.2, asymmetryScore: 0.19 },
    createdAt: "2026-04-14T09:30:01Z",
  },
  {
    id: "scan_004",
    userId: "user_1",
    capturedAt: "2026-04-13T08:00:00Z",
    status: "complete",
    qualityScore: 0.93,
    notes: "Baseline (pre-op)",
    analytics: { swellingPercent: 38.1, asymmetryScore: 0.22 },
    createdAt: "2026-04-13T08:00:01Z",
  },
];

export const MOCK_ANALYTICS: UserAnalytics = {
  userId: "user_1",
  baselineScanId: "scan_004",
  latestScanId: "scan_001",
  summary: {
    totalScans: 4,
    daysSinceBaseline: 3,
    currentSwellingPercent: 12.4,
    currentAsymmetryScore: 0.08,
    peakSwellingPercent: 38.1,
    swellingReductionPercent: 67.5,
  },
  trend: [
    { capturedAt: "2026-04-13T08:00:00Z", swellingPercent: 38.1, asymmetryScore: 0.22 },
    { capturedAt: "2026-04-14T09:30:00Z", swellingPercent: 31.2, asymmetryScore: 0.19 },
    { capturedAt: "2026-04-15T10:00:00Z", swellingPercent: 21.5, asymmetryScore: 0.14 },
    { capturedAt: "2026-04-16T18:00:00Z", swellingPercent: 12.4, asymmetryScore: 0.08 },
  ],
};
