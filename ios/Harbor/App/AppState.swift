import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    enum Tab: String, CaseIterable, Identifiable {
        case map = "Map"
        case places = "Places"
        case activity = "Activity"
        case you = "You"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .map: "location.fill"
            case .places: "mappin.and.ellipse"
            case .activity: "clock.fill"
            case .you: "person.crop.circle.fill"
            }
        }
    }

    @Published private(set) var hasCompletedOnboarding: Bool
    @Published var selectedTab: Tab = .map
    @Published var selectedMemberID: UUID?
    @Published var pendingInvitationCode: String?

    init(defaults: UserDefaults = .standard) {
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: "hasCompletedOnboarding")
        hasCompletedOnboarding = true
    }
}
