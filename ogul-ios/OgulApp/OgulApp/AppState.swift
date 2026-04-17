import Foundation
import Combine

/// Central state object shared across the app via @EnvironmentObject.
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var currentUserID: String = "user_1"
    @Published var scans: [Scan] = Scan.mockList
    @Published var analytics: UserAnalytics? = UserAnalytics.mock
}
