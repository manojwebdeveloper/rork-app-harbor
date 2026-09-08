import SwiftUI

/// Routing-only coordinator for the post-sign-in setup sequence:
/// Create or Join → (Create Circle flow, its own invite step) or (Join Circle → Joined)
/// → Location permission education → Notification permission education → Map tab.
struct OnboardingFlowView: View {
    private enum Route: Hashable {
        case joined(circleName: String)
        case locationPermission
        case notificationPermission
    }

    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var pushNotificationService: PushNotificationService

    let onFinished: () -> Void

    @State private var path: [Route] = []
    @State private var isPresentingJoin = false
    @State private var isPresentingCreate = false
    @State private var joinedCircleName: String?

    var body: some View {
        NavigationStack(path: $path) {
            CreateOrJoinCircleView(
                onCreate: { isPresentingCreate = true },
                onJoin: { isPresentingJoin = true }
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self, destination: destination)
        }
        .fullScreenCover(isPresented: $isPresentingCreate) {
            NewCircleFlowView {
                isPresentingCreate = false
                path.append(.joined(circleName: circleService.selectedCircle?.name ?? "Your circle"))
            }
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
        case let .joined(circleName):
            JoinedView(circleName: circleName) {
                path.append(.locationPermission)
            }
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)

        case .locationPermission:
            LocationPermissionEducationView(
                onContinue: {
                    locationService.requestWhenInUseAuthorization()
                    path.append(.notificationPermission)
                },
                onSkip: { path.append(.notificationPermission) }
            )
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)

        case .notificationPermission:
            NotificationPermissionEducationView(
                onContinue: {
                    Task { await pushNotificationService.requestAuthorizationAndRegister() }
                    onFinished()
                },
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
