import { Nav } from "@/components/Nav";
import { ScanCard } from "@/components/ScanCard";
import { AnalyticsChart } from "@/components/AnalyticsChart";
import { MOCK_ANALYTICS, MOCK_SCANS } from "@/lib/mock-data";

export default function DashboardPage() {
  const { summary, trend } = MOCK_ANALYTICS;

  return (
    <>
      <Nav />
      <main className="mx-auto max-w-5xl px-6 py-10">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-slate-900">Recovery Dashboard</h1>
          <p className="mt-1 text-sm text-slate-500">
            {summary.daysSinceBaseline} days since baseline · {summary.totalScans} scans
          </p>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          <SummaryCard
            label="Current Swelling"
            value={`${summary.currentSwellingPercent.toFixed(1)}%`}
            sub="vs baseline"
            color="text-brand-600"
          />
          <SummaryCard
            label="Asymmetry Score"
            value={summary.currentAsymmetryScore.toFixed(2)}
            sub="lower is better"
            color="text-slate-700"
          />
          <SummaryCard
            label="Swelling Reduced"
            value={`${summary.swellingReductionPercent.toFixed(0)}%`}
            sub="from peak"
            color="text-green-600"
          />
          <SummaryCard
            label="Total Scans"
            value={String(summary.totalScans)}
            sub="sessions logged"
            color="text-slate-700"
          />
        </div>

        {/* Charts */}
        <div className="mt-10 grid gap-6 sm:grid-cols-2">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-base font-semibold text-slate-900">
              Swelling Over Time
            </h2>
            <AnalyticsChart
              trend={trend}
              metric="swellingPercent"
              label="Swelling %"
              color="#0c8ee7"
            />
          </div>
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-base font-semibold text-slate-900">
              Asymmetry Over Time
            </h2>
            <AnalyticsChart
              trend={trend}
              metric="asymmetryScore"
              label="Asymmetry Score"
              color="#7c3aed"
            />
          </div>
        </div>

        {/* Recent Scans */}
        <div className="mt-10">
          <h2 className="mb-4 text-base font-semibold text-slate-900">Recent Scans</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            {MOCK_SCANS.slice(0, 4).map((scan) => (
              <ScanCard key={scan.id} scan={scan} />
            ))}
          </div>
        </div>
      </main>
    </>
  );
}

function SummaryCard({
  label,
  value,
  sub,
  color,
}: {
  label: string;
  value: string;
  sub: string;
  color: string;
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <p className="text-xs font-medium text-slate-500">{label}</p>
      <p className={`mt-1 text-2xl font-bold ${color}`}>{value}</p>
      <p className="mt-0.5 text-xs text-slate-400">{sub}</p>
    </div>
  );
}
