import Foundation

// MARK: - Scan Status

enum ScanStatus: String, Codable, CaseIterable {
    case created
    case uploaded
    case queued
    case processing
    case complete
    case failed

    var displayLabel: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .created:    return "gray"
        case .uploaded:   return "blue"
        case .queued:     return "yellow"
        case .processing: return "orange"
        case .complete:   return "green"
        case .failed:     return "red"
        }
    }
}

// MARK: - Analytics

struct ScanAnalytics: Codable {
    let swellingPercent: Double
    let asymmetryScore: Double
}

// MARK: - Scan

struct Scan: Identifiable, Codable {
    let id: String
    let userId: String
    let capturedAt: Date
    var status: ScanStatus
    var qualityScore: Double?
    var notes: String
    var analytics: ScanAnalytics?
    let createdAt: Date
}

// MARK: - Mock Data

extension Scan {
    static let mockList: [Scan] = [
        Scan(
            id: "scan_001",
            userId: "user_1",
            capturedAt: Date().addingTimeInterval(-3600),
            status: .complete,
            qualityScore: 0.91,
            notes: "Day 3 post-op, improving",
            analytics: ScanAnalytics(swellingPercent: 12.4, asymmetryScore: 0.08),
            createdAt: Date().addingTimeInterval(-3590)
        ),
        Scan(
            id: "scan_002",
            userId: "user_1",
            capturedAt: Date().addingTimeInterval(-86400),
            status: .complete,
            qualityScore: 0.88,
            notes: "Day 2 post-op",
            analytics: ScanAnalytics(swellingPercent: 21.5, asymmetryScore: 0.14),
            createdAt: Date().addingTimeInterval(-86390)
        ),
        Scan(
            id: "scan_003",
            userId: "user_1",
            capturedAt: Date().addingTimeInterval(-172800),
            status: .complete,
            qualityScore: 0.87,
            notes: "Day 1 post-op",
            analytics: ScanAnalytics(swellingPercent: 31.2, asymmetryScore: 0.19),
            createdAt: Date().addingTimeInterval(-172790)
        ),
    ]
}

// MARK: - UserAnalytics

struct AnalyticsTrendPoint: Codable, Identifiable {
    var id: String { capturedAt.description }
    let capturedAt: Date
    let swellingPercent: Double
    let asymmetryScore: Double
}

struct AnalyticsSummary: Codable {
    let totalScans: Int
    let daysSinceBaseline: Int
    let currentSwellingPercent: Double
    let currentAsymmetryScore: Double
    let peakSwellingPercent: Double
    let swellingReductionPercent: Double
}

struct UserAnalytics: Codable {
    let userId: String
    let baselineScanId: String
    let latestScanId: String
    let summary: AnalyticsSummary
    let trend: [AnalyticsTrendPoint]
}

extension UserAnalytics {
    static let mock = UserAnalytics(
        userId: "user_1",
        baselineScanId: "scan_003",
        latestScanId: "scan_001",
        summary: AnalyticsSummary(
            totalScans: 3,
            daysSinceBaseline: 2,
            currentSwellingPercent: 12.4,
            currentAsymmetryScore: 0.08,
            peakSwellingPercent: 31.2,
            swellingReductionPercent: 60.3
        ),
        trend: [
            AnalyticsTrendPoint(capturedAt: Date().addingTimeInterval(-172800), swellingPercent: 31.2, asymmetryScore: 0.19),
            AnalyticsTrendPoint(capturedAt: Date().addingTimeInterval(-86400), swellingPercent: 21.5, asymmetryScore: 0.14),
            AnalyticsTrendPoint(capturedAt: Date().addingTimeInterval(-3600), swellingPercent: 12.4, asymmetryScore: 0.08),
        ]
    )
}
