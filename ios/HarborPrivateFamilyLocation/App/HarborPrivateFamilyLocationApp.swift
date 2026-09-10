import Combine
import FirebaseAuth
import SwiftUI

@main
@MainActor
struct HarborPrivateFamilyLocationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState: AppState
    @StateObject private var authService: AuthService
    @StateObject private var circleService: CircleService
    @StateObject private var locationService: LocationService
    @StateObject private var placesService: PlacesService
    @StateObject private var activityService: ActivityService
    @StateObject private var pushNotificationService: PushNotificationService
    @StateObject private var userPreferencesService: UserPreferencesService

    init() {
        let firebaseConfigured = FirebaseBootstrap.configureIfPossible()
        _appState = StateObject(wrappedValue: AppState())
        _authService = StateObject(wrappedValue: AuthService(firebaseConfigured: firebaseConfigured))
        _circleService = StateObject(wrappedValue: CircleService(firebaseConfigured: firebaseConfigured))
        _locationService = StateObject(wrappedValue: LocationService(firebaseConfigured: firebaseConfigured))
        _placesService = StateObject(wrappedValue: PlacesService(firebaseConfigured: firebaseConfigured))
        _activityService = StateObject(wrappedValue: ActivityService(firebaseConfigured: firebaseConfigured))
        _pushNotificationService = StateObject(wrappedValue: PushNotificationService(firebaseConfigured: firebaseConfigured))
        _userPreferencesService = StateObject(wrappedValue: UserPreferencesService(firebaseConfigured: firebaseConfigured))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(circleService)
                .environmentObject(locationService)
                .environmentObject(placesService)
                .environmentObject(activityService)
                .environmentObject(pushNotificationService)
                .environmentObject(userPreferencesService)
                .tint(Color(.calmTeal))
                .preferredColorScheme(userPreferencesService.appearancePreference.colorScheme)
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
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var userPreferencesService: UserPreferencesService

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
            locationService.observeSharingCircles(for: authService.user?.uid)
            userPreferencesService.observe(userID: authService.user?.uid)
        }
        .sheet(isPresented: invitationSheetBinding) {
            JoinCircleView(
                initialCode: appState.pendingInvitationCode ?? "",
                onFinished: { appState.pendingInvitationCode = nil }
            )
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
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var placesService: PlacesService
    @EnvironmentObject private var activityService: ActivityService

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
        .task(id: circleService.selectedCircleID) {
            placesService.observePlaces(circleID: circleService.selectedCircleID)
            activityService.observeCircle(circleID: circleService.selectedCircleID)
        }
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
                    // A plain tint, not its own `.glassEffect()` — nesting a
                    // second glass surface inside the bar's own glass capsule
                    // (both in one GlassEffectContainer, overlapping) made the
                    // system merge/composite them in front of this label. The
                    // bar's single glass surface below is enough to read this
                    // highlight as translucent along with everything else.
                    .background(selection == tab ? Color(.seaGlass).opacity(0.75) : .clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(7)
        .harborGlass(in: Capsule(), fallback: .regularMaterial)
        .overlay { Capsule().stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5) }
        .shadow(color: .black.opacity(0.10), radius: 20, y: 8)
    }
}
