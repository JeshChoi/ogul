export type ScanStatus =
  | "created"
  | "uploaded"
  | "queued"
  | "processing"
  | "complete"
  | "failed";

export interface ScanAnalytics {
  swellingPercent: number;
  asymmetryScore: number;
}

export interface Scan {
  id: string;
  userId: string;
  capturedAt: string;
  status: ScanStatus;
  qualityScore: number | null;
  notes: string;
  analytics: ScanAnalytics | null;
  createdAt: string;
}

export interface AnalyticsTrendPoint {
  capturedAt: string;
  swellingPercent: number;
  asymmetryScore: number;
}

export interface AnalyticsSummary {
  totalScans: number;
  daysSinceBaseline: number;
  currentSwellingPercent: number;
  currentAsymmetryScore: number;
  peakSwellingPercent: number;
  swellingReductionPercent: number;
}

export interface UserAnalytics {
  userId: string;
  baselineScanId: string;
  latestScanId: string;
  summary: AnalyticsSummary;
  trend: AnalyticsTrendPoint[];
}
