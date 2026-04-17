import { Nav } from "@/components/Nav";
import { ScanTimeline } from "@/components/ScanTimeline";
import { MOCK_SCANS } from "@/lib/mock-data";

export default function ScansPage() {
  return (
    <>
      <Nav />
      <main className="mx-auto max-w-2xl px-6 py-10">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-slate-900">Scan Timeline</h1>
          <p className="mt-1 text-sm text-slate-500">
            {MOCK_SCANS.length} scans · most recent first
          </p>
        </div>
        <ScanTimeline scans={MOCK_SCANS} />
      </main>
    </>
  );
}
