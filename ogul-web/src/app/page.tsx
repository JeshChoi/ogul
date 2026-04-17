import Link from "next/link";

const FEATURES = [
  {
    icon: "📱",
    title: "Guided iPhone Capture",
    desc: "Consistent, repeatable scans using TrueDepth — not just photos.",
  },
  {
    icon: "📈",
    title: "Longitudinal Analytics",
    desc: "Track swelling reduction, asymmetry, and surface change day over day.",
  },
  {
    icon: "🏥",
    title: "Built for Recovery",
    desc: "Designed for post-surgical monitoring with objective, geometric metrics.",
  },
];

export default function LandingPage() {
  return (
    <main className="min-h-screen bg-white">
      {/* Hero */}
      <section className="bg-gradient-to-b from-brand-50 to-white px-6 py-24 text-center">
        <span className="inline-block rounded-full bg-brand-100 px-4 py-1 text-xs font-semibold uppercase tracking-widest text-brand-700">
          Early Access
        </span>
        <h1 className="mt-6 text-5xl font-bold tracking-tight text-slate-900 sm:text-6xl">
          A Fitbit for{" "}
          <span className="text-brand-600">Facial Recovery</span>
        </h1>
        <p className="mx-auto mt-6 max-w-2xl text-lg text-slate-600">
          Ogul tracks how your face changes after surgery — objectively, over time.
          Guided 3D scans from your iPhone. Quantitative analytics you can act on.
        </p>
        <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
          <Link
            href="/dashboard"
            className="rounded-xl bg-brand-600 px-8 py-3 text-sm font-semibold text-white shadow hover:bg-brand-700 transition-colors"
          >
            View Demo Dashboard
          </Link>
          <Link
            href="/scans"
            className="rounded-xl border border-slate-300 px-8 py-3 text-sm font-semibold text-slate-700 hover:border-brand-400 transition-colors"
          >
            Scan Timeline
          </Link>
        </div>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-5xl px-6 py-20">
        <h2 className="text-center text-2xl font-bold text-slate-900">
          How It Works
        </h2>
        <div className="mt-12 grid gap-8 sm:grid-cols-3">
          {FEATURES.map((f) => (
            <div
              key={f.title}
              className="rounded-2xl border border-slate-100 bg-slate-50 p-6"
            >
              <div className="text-3xl">{f.icon}</div>
              <h3 className="mt-4 text-base font-semibold text-slate-900">{f.title}</h3>
              <p className="mt-2 text-sm text-slate-600">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Data Flow */}
      <section className="bg-slate-900 px-6 py-20 text-white">
        <div className="mx-auto max-w-3xl text-center">
          <h2 className="text-2xl font-bold">The Pipeline</h2>
          <div className="mt-10 flex flex-col items-center gap-3 sm:flex-row sm:justify-center sm:gap-0">
            {["Guided Scan", "Upload", "Process", "Analytics"].map((step, i, arr) => (
              <div key={step} className="flex items-center gap-3">
                <div className="rounded-xl bg-white/10 px-5 py-3 text-sm font-medium">
                  {step}
                </div>
                {i < arr.length - 1 && (
                  <span className="hidden text-slate-500 sm:block">→</span>
                )}
              </div>
            ))}
          </div>
          <p className="mt-8 text-sm text-slate-400">
            Each scan is aligned, compared against your baseline, and translated into
            meaningful recovery metrics.
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-100 px-6 py-8 text-center text-xs text-slate-400">
        © 2026 Ogul. All rights reserved.
      </footer>
    </main>
  );
}
