import Combine
import FirebaseAuth
import SwiftUI

@main
@MainActor
struct HarborPrivateFamilyLocationApp: App {
    @StateObject private var appState: AppState
    @StateObject private var authService: AuthService
    @StateObject private var circleService: CircleService
    @StateObject private var locationService = LocationService()

    init() {
        let firebaseConfigured = FirebaseBootstrap.configureIfPossible()
        _appState = StateObject(wrappedValue: AppState())
        _authService = StateObject(wrappedValue: AuthService(firebaseConfigured: firebaseConfigured))
        _circleService = StateObject(wrappedValue: CircleService(firebaseConfigured: firebaseConfigured))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(circleService)
                .environmentObject(locationService)
                .tint(Color(.calmTeal))
                .onOpenURL { url in
                    if let code = InvitationLink.code(from: url) {
                        appState.pendingInvitationCode = code
                    }
                }
        }
    }
}

/// Routes between launch, intro, sign-in, circle setup and the four-tab shell.
private struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var circleService: CircleService

    var body: some View {
        Group {
            if !authService.isFirebaseConfigured {
                FirebaseSetupRequiredView()
            } else if authService.isLoading {
                LaunchView()
            } else if !appState.hasCompletedIntro {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState.completeIntro()
                    }
                }
            } else if authService.user == nil {
                SignInView()
            } else if !appState.hasCompletedSetup {
                OnboardingFlowView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState.selectedTab = .map
                        appState.completeSetup()
                    }
                }
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.user?.uid)
        .task(id: authService.user?.uid) {
            circleService.observeCircles(for: authService.user?.uid)
        }
        .sheet(isPresented: invitationSheetBinding) {
            JoinCircleView(initialCode: appState.pendingInvitationCode ?? "") {
                appState.pendingInvitationCode = nil
            }
            .environmentObject(circleService)
        }
    }

    private var invitationSheetBinding: Binding<Bool> {
        Binding(
            get: {
                authService.user != nil && appState.pendingInvitationCode != nil
            },
            set: { isPresented in
                if !isPresented {
                    appState.pendingInvitationCode = nil
                }
            }
        )
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .map:
                    MainMapView()
                case .places:
                    PlacesView()
                case .activity:
                    ActivityView()
                case .you:
                    YouView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HarborPrivateFamilyLocationTabBar(selection: $appState.selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
    }
}

private struct HarborPrivateFamilyLocationTabBar: View {
    @Binding var selection: AppState.Tab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppState.Tab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selection == tab ? Color(.calmTeal) : Color(.slate))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(selection == tab ? Color(.seaGlass).opacity(0.75) : .clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5) }
        .shadow(color: .black.opacity(0.10), radius: 20, y: 8)
    }
}
