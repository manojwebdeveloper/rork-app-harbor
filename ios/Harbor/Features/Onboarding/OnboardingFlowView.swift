import SwiftUI

/// Routing-only coordinator for the post-sign-in setup sequence:
/// Create or Join → (Create Circle → Invite → Joined) or (Join Circle → Joined)
/// → Location permission education → Notification permission education → Map tab.
struct OnboardingFlowView: View {
    private enum Route: Hashable {
        case createCircle
        case invite(circleID: String, circleName: String)
        case joined(circleName: String)
        case locationPermission
        case notificationPermission
    }

    @EnvironmentObject private var circleService: CircleService

    let onFinished: () -> Void

    @State private var path: [Route] = []
    @State private var isPresentingJoin = false
    @State private var joinedCircleName: String?

    var body: some View {
        NavigationStack(path: $path) {
            CreateOrJoinCircleView(
                onCreate: { path.append(.createCircle) },
                onJoin: { isPresentingJoin = true }
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self, destination: destination)
        }
        .sheet(isPresented: $isPresentingJoin, onDismiss: advanceAfterJoin) {
            JoinCircleView(onJoined: { preview in
                joinedCircleName = preview.circleName
            })
            .environmentObject(circleService)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .createCircle:
            CreateCircleView { circleID, circleName in
                path.append(.invite(circleID: circleID, circleName: circleName))
            }

        case let .invite(circleID, circleName):
            InviteView(circleID: circleID) {
                path.append(.joined(circleName: circleName))
            }
            .navigationBarBackButtonHidden()

        case let .joined(circleName):
            JoinedView(circleName: circleName) {
                path.append(.locationPermission)
            }
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)

        case .locationPermission:
            LocationPermissionEducationView(
                onContinue: { path.append(.notificationPermission) },
                onSkip: { path.append(.notificationPermission) }
            )
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)

        case .notificationPermission:
            NotificationPermissionEducationView(
                onContinue: onFinished,
                onSkip: onFinished
            )
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    /// Joining happens in a sheet, so the confirmation step is pushed once it closes.
    private func advanceAfterJoin() {
        guard let circleName = joinedCircleName else { return }
        joinedCircleName = nil
        path.append(.joined(circleName: circleName))
    }
}
