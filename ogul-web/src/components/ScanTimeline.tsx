import type { Scan } from "@/types";
import { StatusBadge } from "./ui/Badge";

interface ScanTimelineProps {
  scans: Scan[];
}

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
}

export function ScanTimeline({ scans }: ScanTimelineProps) {
  const sorted = [...scans].sort(
    (a, b) => new Date(b.capturedAt).getTime() - new Date(a.capturedAt).getTime()
  );

  return (
    <div className="relative">
      <div className="absolute left-4 top-0 bottom-0 w-px bg-slate-200" aria-hidden />
      <ul className="space-y-6">
        {sorted.map((scan, i) => (
          <li key={scan.id} className="relative flex gap-5">
            <div
              className={`relative z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 text-xs font-bold ${
                i === 0
                  ? "border-brand-500 bg-brand-500 text-white"
                  : "border-slate-300 bg-white text-slate-500"
              }`}
            >
              {sorted.length - i}
            </div>
            <div className="flex-1 rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
              <div className="flex items-center justify-between gap-2">
                <p className="text-sm font-medium text-slate-700">
                  {formatDate(scan.capturedAt)}
                </p>
                <StatusBadge status={scan.status} />
              </div>
              {scan.notes && (
                <p className="mt-1 text-xs text-slate-500 italic">"{scan.notes}"</p>
              )}
              {scan.analytics && (
                <div className="mt-3 flex gap-4">
                  <div>
                    <span className="text-xs text-slate-400">Swelling </span>
                    <span className="text-sm font-semibold text-brand-600">
                      {scan.analytics.swellingPercent.toFixed(1)}%
                    </span>
                  </div>
                  <div>
                    <span className="text-xs text-slate-400">Asymmetry </span>
                    <span className="text-sm font-semibold text-slate-700">
                      {scan.analytics.asymmetryScore.toFixed(2)}
                    </span>
                  </div>
                </div>
              )}
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
