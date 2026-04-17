import type { AnalyticsTrendPoint } from "@/types";

interface AnalyticsChartProps {
  trend: AnalyticsTrendPoint[];
  metric: "swellingPercent" | "asymmetryScore";
  label: string;
  color?: string;
}

function formatDay(iso: string) {
  return new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export function AnalyticsChart({
  trend,
  metric,
  label,
  color = "#0c8ee7",
}: AnalyticsChartProps) {
  if (trend.length === 0) return null;

  const values = trend.map((p) => p[metric]);
  const max = Math.max(...values) * 1.1;
  const min = 0;
  const range = max - min || 1;

  const width = 500;
  const height = 120;
  const padX = 8;
  const padY = 8;

  const points = trend.map((p, i) => {
    const x = padX + (i / Math.max(trend.length - 1, 1)) * (width - padX * 2);
    const y = height - padY - ((p[metric] - min) / range) * (height - padY * 2);
    return { x, y, point: p };
  });

  const polyline = points.map((p) => `${p.x},${p.y}`).join(" ");
  const area = [
    `M${points[0].x},${height - padY}`,
    ...points.map((p) => `L${p.x},${p.y}`),
    `L${points[points.length - 1].x},${height - padY}`,
    "Z",
  ].join(" ");

  return (
    <div>
      <p className="mb-2 text-sm font-medium text-slate-500">{label}</p>
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full overflow-visible"
        aria-label={label}
      >
        <defs>
          <linearGradient id={`grad-${metric}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.15" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={area} fill={`url(#grad-${metric})`} />
        <polyline
          points={polyline}
          fill="none"
          stroke={color}
          strokeWidth="2"
          strokeLinejoin="round"
          strokeLinecap="round"
        />
        {points.map(({ x, y, point }, i) => (
          <g key={i}>
            <circle cx={x} cy={y} r="3.5" fill={color} />
            <text
              x={x}
              y={height}
              textAnchor="middle"
              fontSize="9"
              fill="#94a3b8"
            >
              {formatDay(point.capturedAt)}
            </text>
          </g>
        ))}
      </svg>
    </div>
  );
}
