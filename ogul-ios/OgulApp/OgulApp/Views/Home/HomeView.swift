import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingScanFlow = false

    private var latestScan: Scan? {
        appState.scans.sorted { $0.capturedAt > $1.capturedAt }.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good morning")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Recovery Dashboard")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)

                    // CTA card
                    Button(action: { showingScanFlow = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Start a Scan")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Capture today's facial scan")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(20)
                        .background(LinearGradient(colors: [.blue, .blue.opacity(0.75)],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing))
                        .cornerRadius(18)
                        .padding(.horizontal)
                    }

                    // Latest scan summary
                    if let scan = latestScan, let analytics = scan.analytics {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Latest Scan")
                                .font(.headline)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                MetricTile(
                                    label: "Swelling",
                                    value: String(format: "%.1f%%", analytics.swellingPercent),
                                    color: .blue
                                )
                                MetricTile(
                                    label: "Asymmetry",
                                    value: String(format: "%.2f", analytics.asymmetryScore),
                                    color: .purple
                                )
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Recovery progress
                    if let a = appState.analytics {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recovery Progress")
                                .font(.headline)
                                .padding(.horizontal)

                            RecoveryProgressCard(analytics: a)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Ogul")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingScanFlow) {
                ScanFlowView()
            }
        }
    }
}

struct MetricTile: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }
}

struct RecoveryProgressCard: View {
    let analytics: UserAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Swelling reduced")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", analytics.summary.swellingReductionPercent))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                Spacer()
                Text("\(analytics.summary.daysSinceBaseline)d since baseline")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: analytics.summary.swellingReductionPercent / 100)
                .tint(.green)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}
