import type { Scan } from "@/types";
import { StatusBadge } from "./ui/Badge";

interface ScanCardProps {
  scan: Scan;
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function ScanCard({ scan }: ScanCardProps) {
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-mono text-slate-400">{scan.id}</p>
          <p className="mt-1 text-sm text-slate-500">{formatDate(scan.capturedAt)}</p>
          {scan.notes && (
            <p className="mt-2 text-sm text-slate-700 italic">"{scan.notes}"</p>
          )}
        </div>
        <StatusBadge status={scan.status} />
      </div>

      {scan.analytics && (
        <div className="mt-4 grid grid-cols-2 gap-3">
          <div className="rounded-lg bg-brand-50 px-4 py-3">
            <p className="text-xs text-brand-600 font-medium">Swelling</p>
            <p className="mt-0.5 text-xl font-bold text-brand-700">
              {scan.analytics.swellingPercent.toFixed(1)}%
            </p>
          </div>
          <div className="rounded-lg bg-slate-50 px-4 py-3">
            <p className="text-xs text-slate-500 font-medium">Asymmetry</p>
            <p className="mt-0.5 text-xl font-bold text-slate-700">
              {scan.analytics.asymmetryScore.toFixed(2)}
            </p>
          </div>
        </div>
      )}

      {scan.qualityScore !== null && (
        <div className="mt-3 flex items-center gap-2">
          <div className="h-1.5 flex-1 rounded-full bg-slate-100">
            <div
              className="h-1.5 rounded-full bg-brand-500"
              style={{ width: `${(scan.qualityScore ?? 0) * 100}%` }}
            />
          </div>
          <span className="text-xs text-slate-400">
            Quality {Math.round((scan.qualityScore ?? 0) * 100)}%
          </span>
        </div>
      )}
    </div>
  );
}
