import type { ScanStatus } from "@/types";

const STATUS_STYLES: Record<ScanStatus, string> = {
  created:    "bg-slate-100 text-slate-600",
  uploaded:   "bg-blue-100 text-blue-700",
  queued:     "bg-yellow-100 text-yellow-700",
  processing: "bg-orange-100 text-orange-700",
  complete:   "bg-green-100 text-green-700",
  failed:     "bg-red-100 text-red-700",
};

interface BadgeProps {
  status: ScanStatus;
}

export function StatusBadge({ status }: BadgeProps) {
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${STATUS_STYLES[status]}`}
    >
      {status}
    </span>
  );
}
