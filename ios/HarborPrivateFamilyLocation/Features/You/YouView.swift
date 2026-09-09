import SwiftUI

struct YouView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var userPreferencesService: UserPreferencesService

    @State private var isShowingCreateOrJoin = false
    @State private var isShowingNewCircle = false
    @State private var isShowingJoinCircle = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                profileSection
                sharingSummarySection

                Section("Your circles") {
                    if circleService.circles.isEmpty {
                        Text("No circles yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(circleService.circles.prefix(3)) { circle in
                            HStack(spacing: 12) {
                                Image(systemName: circle.kind == .family ? "person.3.fill" : "suitcase.rolling.fill")
                                    .foregroundStyle(
                                        circle.kind == .family ? Color(.calmTeal) : Color(.clearSky)
                                    )
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(circle.name)
                                    Text(circle.kind.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Button {
                        isShowingCreateOrJoin = true
                    } label: {
                        Label("Create or join a circle", systemImage: "plus.circle")
                    }

                    NavigationLink {
                        ManageCirclesView()
                    } label: {
                        Label("Manage your circles", systemImage: "person.3.sequence.fill")
                    }
                }

                Section("Location sharing") {
                    NavigationLink("Who can see my location") { LocationSharingSettingsView() }
                    NavigationLink {
                        SharingExpirationPicker()
                    } label: {
                        LabeledContent("Sharing expiration", value: userPreferencesService.sharingExpirationPreference.title)
                    }
                    NavigationLink("Privacy & data") { PrivacyDataView() }
                }

                notificationsSection

                Section("HarborPrivateFamilyLocation Premium") {
                    NavigationLink {
                        SubscriptionView()
                    } label: {
                        LabeledContent("Plan", value: "Free plan")
                    }
                    Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                        Text("Manage or cancel subscription")
                    }
                }

                helpAndSupportSection
                aboutSection
                appearanceSection

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color(.signalRed))
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        authService.signOut()
                    }
                }
            }
            .navigationTitle("You")
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 94) }
            .sheet(isPresented: $isShowingCreateOrJoin) {
                NavigationStack {
                    CreateOrJoinCircleView(
                        onCreate: {
                            isShowingCreateOrJoin = false
                            isShowingNewCircle = true
                        },
                        onJoin: {
                            isShowingCreateOrJoin = false
                            isShowingJoinCircle = true
                        }
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { isShowingCreateOrJoin = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $isShowingNewCircle) {
                NewCircleFlowView { isShowingNewCircle = false }
            }
            .sheet(isPresented: $isShowingJoinCircle) {
                JoinCircleView(onFinished: { isShowingJoinCircle = false })
                    .environmentObject(circleService)
            }
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color(.warmAmber).opacity(0.18))
                    .frame(width: 58, height: 58)
                    .overlay {
                        Text(initials)
                            .font(.title3.bold())
                            .foregroundStyle(Color(.warmAmber))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(authService.displayName)
                        .font(.headline)
                    if let emailAddress = authService.emailAddress, !emailAddress.isEmpty {
                        Text(emailAddress)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Manage profile")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    /// Real per-circle/trip breakdown — "sharing" isn't one on/off switch,
    /// it's a per-circle toggle, so the summary needs to show each one.
    private var sharingSummarySection: some View {
        Section {
            Label(
                locationService.isSharingPaused ? "All sharing is paused" : shareTitle,
                systemImage: locationService.isSharingPaused ? "pause.circle.fill" : "location.fill"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(locationService.isSharingPaused ? Color(.slate) : Color(.calmTeal))

            if !locationService.isSharingPaused {
                ForEach(circleService.circles) { circle in
                    HStack(alignment: .firstTextBaseline) {
                        Text(circle.name)
                            .font(.subheadline)
                        Spacer()
                        Text(statusText(for: circle))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Your circles see your last shared location until you resume.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button(locationService.isSharingPaused ? "Resume sharing" : "Pause sharing") {
                locationService.setSharingPaused(!locationService.isSharingPaused)
            }
        }
    }

    private var shareTitle: String {
        let count = locationService.sharingCircleIDs.count
        if count == 0 { return "Not sharing with anyone" }
        return "Sharing with \(count) circle\(count == 1 ? "" : "s")"
    }

    private func statusText(for circle: FirebaseCircleSummary) -> String {
        guard locationService.sharingCircleIDs.contains(circle.id) else { return "Not sharing" }
        if circle.kind == .trip, let expiresAt = circle.expiresAt {
            return "until \(expiresAt.formatted(date: .omitted, time: .shortened))"
        }
        return "Sharing"
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Arrivals and departures", isOn: notificationBinding(\.arrivalsAndDepartures))
            Toggle("Check-ins from your circle", isOn: notificationBinding(\.checkIns))
            Toggle("Quiet hours", isOn: notificationBinding(\.quietHoursEnabled))

            if userPreferencesService.notificationPreferences.quietHoursEnabled {
                DatePicker(
                    "From",
                    selection: quietHoursDateBinding(\.quietHoursStart),
                    displayedComponents: .hourAndMinute
                )
                DatePicker(
                    "To",
                    selection: quietHoursDateBinding(\.quietHoursEnd),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private func notificationBinding(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { userPreferencesService.notificationPreferences[keyPath: keyPath] },
            set: { newValue in
                var updated = userPreferencesService.notificationPreferences
                updated[keyPath: keyPath] = newValue
                save(updated)
            }
        )
    }

    private func quietHoursDateBinding(_ keyPath: WritableKeyPath<NotificationPreferences, Int>) -> Binding<Date> {
        Binding(
            get: { Self.date(fromMinutes: userPreferencesService.notificationPreferences[keyPath: keyPath]) },
            set: { newValue in
                var updated = userPreferencesService.notificationPreferences
                updated[keyPath: keyPath] = Self.minutes(from: newValue)
                save(updated)
            }
        )
    }

    private func save(_ preferences: NotificationPreferences) {
        errorMessage = nil
        Task {
            do {
                try await userPreferencesService.updateNotificationPreferences(preferences)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private static func date(fromMinutes minutes: Int) -> Date {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private var helpAndSupportSection: some View {
        Section("Help & support") {
            Link(destination: URL(string: "mailto:\(HarborSupportContact.email)")!) {
                Label("Email us", systemImage: "envelope")
            }
            Link(destination: HarborSupportContact.helpCenterURL) {
                Label("Browse help topics", systemImage: "questionmark.circle")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Link(destination: HarborSupportContact.privacyPolicyURL) {
                Text("Privacy Policy")
            }
            Link(destination: HarborSupportContact.termsOfServiceURL) {
                Text("Terms of Service")
            }
            LabeledContent("About HarborPrivateFamilyLocation", value: "Version \(HarborSupportContact.appVersion)")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Appearance", selection: appearanceBinding) {
                ForEach(AppearanceOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
    }

    private var appearanceBinding: Binding<AppearanceOption> {
        Binding(
            get: { userPreferencesService.appearancePreference },
            set: { newValue in
                errorMessage = nil
                Task {
                    do {
                        try await userPreferencesService.updateAppearancePreference(newValue)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        )
    }

    private var initials: String {
        let components = authService.displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        let value = String(components)
        return value.isEmpty ? "H" : value.uppercased()
    }
}

/// Support/legal contact points. Privacy Policy, Terms of Service and the
/// help center are TODO placeholders — real content/URLs are needed before
/// App Store submission (Privacy Policy and Terms are a hard submission
/// requirement, not optional). See the final report.
enum HarborSupportContact {
    static let email = "support@appamore.com"
    static let privacyPolicyURL = URL(string: "https://harbor.app.invalid/TODO-privacy-policy")!
    static let termsOfServiceURL = URL(string: "https://harbor.app.invalid/TODO-terms-of-service")!
    static let helpCenterURL = URL(string: "https://harbor.app.invalid/TODO-help-center")!

    static var appVersion: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        guard let buildNumber, !buildNumber.isEmpty, buildNumber != shortVersion else { return shortVersion }
        return "\(shortVersion) (\(buildNumber))"
    }
}
