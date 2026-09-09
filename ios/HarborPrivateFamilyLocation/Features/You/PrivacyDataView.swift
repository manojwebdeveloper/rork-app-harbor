import SwiftUI
import UIKit

struct PrivacyDataView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var userPreferencesService: UserPreferencesService

    @State private var isSharingBatteryLevel = true
    @State private var isSharingLowBatteryAlerts = true
    @State private var isDeletingHistory = false
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Toggle(isOn: $isSharingBatteryLevel) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Battery level")
                        Text("Shows your battery percentage next to your name, so your family knows when your phone may run out.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $isSharingLowBatteryAlerts) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Low battery alerts")
                        Text("Let your circle know when you drop below 20%.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("What your circle sees")
            } footer: {
                Text("Your circle sees your battery percentage. They never see charging history or usage.")
            }

            Section("Preview") {
                batteryPreviewChip
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
            }

            Section("Who can see you") {
                LabeledContent("Circle memberships", value: "\(circleService.circles.count)")
                LabeledContent(
                    "Location sharing",
                    value: locationService.isSharingPaused ? "Paused" : "\(locationService.sharingCircleIDs.count) circle\(locationService.sharingCircleIDs.count == 1 ? "" : "s")"
                )

                if !activeTripCircles.isEmpty {
                    ForEach(activeTripCircles) { circle in
                        LabeledContent(circle.name, value: circle.expiresAt.map { "until \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Active")
                    }
                }

                NavigationLink {
                    SharingExpirationPicker()
                } label: {
                    LabeledContent("When sharing should stop", value: userPreferencesService.sharingExpirationPreference.title)
                }

                Button(locationService.isSharingPaused ? "Resume all sharing" : "Pause all sharing") {
                    locationService.setSharingPaused(!locationService.isSharingPaused)
                }
            }

            Section {
                LabeledContent("How long we keep it", value: "We don't keep a history")
                Button(isDeletingHistory ? "Clearing…" : "Delete location history now") {
                    Task { await deleteHistory() }
                }
                .disabled(isDeletingHistory)
            } header: {
                Text("Your location history")
            } footer: {
                Text("Harbor only ever stores your current position while sharing is on — it's replaced every time you move, not logged. This clears the last position your circles can see right now.")
            }

            Section {
                LabeledContent("This device", value: "Signed in")
                Button("Sign out", role: .destructive) {
                    authService.signOut()
                }
            } header: {
                Text("Devices signed in")
            } footer: {
                Text("Firebase doesn't provide a list of every device or session signed in to your account — signing out only ends the session on this device. If you think another device has access you didn't authorize, delete your account below and create a new one.")
            }

            Section("Your account") {
                Button(isExporting ? "Preparing…" : "Export a copy of your data") {
                    Task { await exportData() }
                }
                .disabled(isExporting)

                if let exportedFileURL {
                    ShareLink(item: exportedFileURL) {
                        Label("Share your data export", systemImage: "square.and.arrow.up")
                    }
                }

                NavigationLink {
                    DeleteAccountView()
                } label: {
                    Text("Delete account")
                        .foregroundStyle(Color(.signalRed))
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle("Privacy & data")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var activeTripCircles: [FirebaseCircleSummary] {
        circleService.circles.filter { $0.kind == .trip }
    }

    /// Mirrors the map chip so the setting's effect is obvious.
    private var batteryPreviewChip: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(Color(.warmAmber).opacity(0.16))
                .frame(width: 34, height: 34)
                .overlay { Circle().stroke(Color(.warmAmber), lineWidth: 1.5) }
                .overlay {
                    Text(initials)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(.warmAmber))
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(authService.displayName)
                    .font(.system(size: 15, weight: .bold))

                HStack(spacing: 5) {
                    Text(locationService.isSharingPaused ? "Sharing paused" : "Live")

                    if isSharingBatteryLevel, let batteryPercent {
                        Text("|")
                            .foregroundStyle(.tertiary)
                        HStack(spacing: 3) {
                            Image(systemName: BatteryGlyph.symbol(for: batteryPercent))
                            Text("\(batteryPercent)%")
                                .fontWeight(.semibold)
                        }
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 9)
        .padding(.trailing, 16)
        .padding(.vertical, 9)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color(.mineralBorder), lineWidth: 0.5) }
        .onAppear { UIDevice.current.isBatteryMonitoringEnabled = true }
    }

    private var initials: String {
        let letters = authService.displayName.split(separator: " ").compactMap(\.first).prefix(2)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private var batteryPercent: Int? {
        UIDevice.current.batteryLevel >= 0 ? Int(UIDevice.current.batteryLevel * 100) : nil
    }

    private func deleteHistory() async {
        isDeletingHistory = true
        errorMessage = nil
        defer { isDeletingHistory = false }
        do {
            try await locationService.deleteLocationHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportData() async {
        isExporting = true
        errorMessage = nil
        defer { isExporting = false }
        do {
            exportedFileURL = try await authService.exportData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
