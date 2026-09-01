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

    private enum Key {
        static let intro = "hasCompletedOnboarding"
        static let setup = "hasCompletedCircleSetup"
    }

    /// The 3-page privacy intro has been seen.
    @Published private(set) var hasCompletedIntro: Bool
    /// The post-sign-in setup sequence (circle + permission education) has been finished.
    @Published private(set) var hasCompletedSetup: Bool
    @Published var selectedTab: Tab = .map
    @Published var selectedMemberID: UUID?
    @Published var pendingInvitationCode: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedIntro = defaults.bool(forKey: Key.intro)
        hasCompletedSetup = defaults.bool(forKey: Key.setup)
    }

    func completeIntro() {
        defaults.set(true, forKey: Key.intro)
        hasCompletedIntro = true
    }

    func completeSetup() {
        defaults.set(true, forKey: Key.setup)
        hasCompletedSetup = true
    }
}
