import SwiftUI

struct AnalyticsSummaryView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                if let analytics = appState.analytics {
                    AnalyticsContentView(analytics: analytics)
                } else {
                    ContentUnavailableView(
                        "No Analytics Yet",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Complete at least two scans to see trends.")
                    )
                    .padding(.top, 60)
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

private struct AnalyticsContentView: View {
    let analytics: UserAnalytics

    var body: some View {
        VStack(spacing: 24) {
            // Summary header
            HStack {
                SummaryStatView(
                    label: "Total Scans",
                    value: "\(analytics.summary.totalScans)",
                    color: .blue
                )
                SummaryStatView(
                    label: "Days Tracked",
                    value: "\(analytics.summary.daysSinceBaseline)",
                    color: .purple
                )
                SummaryStatView(
                    label: "Reduced",
                    value: String(format: "%.0f%%", analytics.summary.swellingReductionPercent),
                    color: .green
                )
            }
            .padding(.horizontal)

            Divider()

            // Current metrics
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Current Status")

                HStack(spacing: 12) {
                    MetricCard(
                        label: "Swelling",
                        value: String(format: "%.1f%%", analytics.summary.currentSwellingPercent),
                        subtext: String(format: "Peak: %.1f%%", analytics.summary.peakSwellingPercent),
                        color: .blue
                    )
                    MetricCard(
                        label: "Asymmetry",
                        value: String(format: "%.2f", analytics.summary.currentAsymmetryScore),
                        subtext: "lower is better",
                        color: .purple
                    )
                }
                .padding(.horizontal)
            }

            // Trend chart
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Swelling Trend")

                SwellingSparkline(trend: analytics.trend)
                    .frame(height: 80)
                    .padding(.horizontal)
            }

            // Trend list
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Scan History")

                ForEach(analytics.trend.reversed()) { point in
                    TrendRow(point: point)
                        .padding(.horizontal)
                }
            }

            Spacer(minLength: 40)
        }
        .padding(.top)
    }
}

// MARK: - Sub-views

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
    }
}

private struct SummaryStatView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MetricCard: View {
    let label: String
    let value: String
    let subtext: String
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
            Text(subtext)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(14)
    }
}

private struct SwellingSparkline: View {
    let trend: [AnalyticsTrendPoint]

    var body: some View {
        GeometryReader { geo in
            let values = trend.map { $0.swellingPercent }
            let maxVal = values.max() ?? 1
            let min = values.min() ?? 0
            let range = maxVal - min == 0 ? 1.0 : maxVal - min
            let w = geo.size.width
            let h = geo.size.height

            Path { path in
                for (i, point) in trend.enumerated() {
                    let x = CGFloat(i) / CGFloat(max(trend.count - 1, 1)) * w
                    let y = h - CGFloat((point.swellingPercent - min) / range) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct TrendRow: View {
    let point: AnalyticsTrendPoint

    var body: some View {
        HStack {
            Text(point.capturedAt, style: .date)
                .font(.subheadline)
            Spacer()
            Text(String(format: "%.1f%%", point.swellingPercent))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            Text(String(format: "%.2f", point.asymmetryScore))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
