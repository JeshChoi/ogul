import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case decodingFailed(Error)
    case serverError(Int, String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid URL."
        case .decodingFailed(let e):  return "Decoding failed: \(e.localizedDescription)"
        case .serverError(let c, let m): return "Server error \(c): \(m)"
        case .unknown(let e):         return e.localizedDescription
        }
    }
}

// MARK: - API Service

/// Typed client for the ogul-backend REST API.
/// Phase 1: methods are stubbed with mock data.
/// Phase 2: replace stub bodies with real URLSession calls.
final class APIService {
    static let shared = APIService()

    private let baseURL: URL
    private let decoder: JSONDecoder

    private init() {
        let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String
            ?? "http://localhost:8080"
        self.baseURL = URL(string: urlString)!

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - Health

    func health() async throws -> Bool {
        // Phase 1 stub
        return true
    }

    // MARK: - Scans

    func createScan(userId: String, capturedAt: Date, notes: String) async throws -> Scan {
        // Phase 1 stub — returns a mock scan
        return Scan(
            id: "scan_\(Int.random(in: 1000...9999))",
            userId: userId,
            capturedAt: capturedAt,
            status: .created,
            qualityScore: nil,
            notes: notes,
            analytics: nil,
            createdAt: Date()
        )
    }

    func getScan(id: String) async throws -> Scan {
        // Phase 1 stub
        return Scan.mockList.first ?? Scan.mockList[0]
    }

    // MARK: - Users

    func getUserScans(userId: String) async throws -> [Scan] {
        // Phase 1 stub
        return Scan.mockList
    }

    func getUserAnalytics(userId: String) async throws -> UserAnalytics {
        // Phase 1 stub
        return UserAnalytics.mock
    }

    // MARK: - Real request helper (Phase 2+)

    private func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.unknown(URLError(.badServerResponse))
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(http.statusCode, message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
