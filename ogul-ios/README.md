# ogul-ios

iOS app for guided facial capture and recovery tracking.

---

## Stack

- **Swift / SwiftUI**
- **iOS 17+**
- **ARKit + TrueDepth** (Phase 3+)

---

## Project Structure

```
OgulApp/
├── OgulApp.swift                    # @main App entry point
├── AppState.swift                   # Global ObservableObject shared via EnvironmentObject
├── ContentView.swift                # RootView (onboarding gate) + MainTabView
├── Models/
│   └── Scan.swift                   # Scan, Analytics, UserAnalytics, ScanStatus
├── Services/
│   └── APIService.swift             # Typed REST client (Phase 1: stubbed)
└── Views/
    ├── Onboarding/
    │   └── OnboardingView.swift     # 3-page onboarding flow
    ├── Home/
    │   └── HomeView.swift           # Dashboard: latest scan + recovery progress
    ├── Scan/
    │   └── ScanFlowView.swift       # Guided scan flow (ARKit placeholder)
    ├── History/
    │   └── ScanHistoryView.swift    # Chronological scan list
    └── Analytics/
        └── AnalyticsSummaryView.swift # Swelling trend, asymmetry, sparkline
```

---

## Setup

1. Open Xcode → **File > New > Project** → iOS App
2. Set product name: `OgulApp`, bundle ID: `com.yourname.ogul`
3. Delete the generated `ContentView.swift`
4. Drag all files from `OgulApp/` into the Xcode project navigator
5. Build and run on a device or simulator (iOS 17+)

> **Note:** ARKit TrueDepth features require a physical iPhone with Face ID (iPhone X or later). Simulators only run the placeholder UI.

---

## Environment Config

Add `API_BASE_URL` to your `Info.plist` or scheme environment:

```
API_BASE_URL = http://localhost:8080
```

---

## Screens

| Screen | Description |
|--------|-------------|
| Onboarding | 3-step intro, first-run only |
| Home | Recovery dashboard, scan CTA |
| Scan Flow | Guided capture session (ARKit placeholder) |
| Scan History | Chronological list with status + analytics |
| Analytics Summary | Trend chart, summary cards |

---

## Roadmap

- **Phase 1** (current): Full SwiftUI screen shells, mocked data, API service stub
- **Phase 2**: Real API calls, auth, scan upload to signed URL
- **Phase 3**: ARKit TrueDepth integration, depth frame capture
- **Phase 4**: On-device scan quality validation
