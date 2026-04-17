# ogul-web

Next.js dashboard and landing page for Ogul.

---

## Stack

- **Next.js 14** (App Router)
- **TypeScript**
- **Tailwind CSS**

---

## Project Structure

```
src/
├── app/
│   ├── layout.tsx          # Root layout, global styles
│   ├── page.tsx            # Landing page
│   ├── dashboard/
│   │   └── page.tsx        # Recovery dashboard (summary + charts)
│   └── scans/
│       └── page.tsx        # Scan timeline
├── components/
│   ├── ui/
│   │   └── Badge.tsx       # Status badge component
│   ├── Nav.tsx             # Navigation bar
│   ├── ScanCard.tsx        # Individual scan card
│   ├── ScanTimeline.tsx    # Chronological scan list
│   └── AnalyticsChart.tsx  # SVG trend chart
├── lib/
│   ├── api.ts              # Typed API client
│   └── mock-data.ts        # Phase 1 mock data
└── types/
    └── index.ts            # Shared TypeScript types
```

---

## Running Locally

```bash
npm install
cp .env.example .env.local
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

Set `NEXT_PUBLIC_API_URL` in `.env.local` to point at `ogul-backend`.

---

## Pages

| Route | Description |
|-------|-------------|
| `/` | Landing page |
| `/dashboard` | Recovery summary, analytics charts, recent scans |
| `/scans` | Full scan timeline |

---

## Roadmap

- **Phase 1** (current): Mocked data, all pages functional
- **Phase 2**: Connect to real API, add auth
- **Phase 3**: Heatmap visualization, scan detail view
