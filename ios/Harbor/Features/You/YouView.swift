import SwiftUI

struct YouView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        NavigationStack {
            List {
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

                Section {
                    Label(
                        locationService.isSharingPaused
                            ? "Location sharing is paused"
                            : "Location sharing is on",
                        systemImage: locationService.isSharingPaused ? "pause.circle.fill" : "location.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        locationService.isSharingPaused ? Color(.slate) : Color(.calmTeal)
                    )

                    Button(locationService.isSharingPaused ? "Resume sharing" : "Pause sharing") {
                        locationService.setSharingPaused(!locationService.isSharingPaused)
                    }
                }

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

                    NavigationLink {
                        CircleManagementView()
                    } label: {
                        Label("Create or join a circle", systemImage: "person.3.sequence.fill")
                    }
                }

                Section("Location sharing") {
                    NavigationLink("Who can see my location") { LocationSharingSettingsView() }
                    NavigationLink("Privacy & data") { PrivacyDataView() }
                }

                Section("Harbor Premium") {
                    NavigationLink("Subscription") { SubscriptionView() }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        authService.signOut()
                    }
                }
            }
            .navigationTitle("You")
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 94) }
        }
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
