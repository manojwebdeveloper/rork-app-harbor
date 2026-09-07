import SwiftUI

struct LocationSharingSettingsView: View {
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService

    @State private var pendingCircleID: String?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Who can see my location") {
                if circleService.circles.isEmpty {
                    Text("No circles yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(circleService.circles) { circle in
                        Toggle(isOn: sharingBinding(for: circle.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(circle.name)
                                Text(circle.kind.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(Color(.safeGreen))
                        .disabled(pendingCircleID == circle.id || locationService.isSharingPaused)
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                }
            }

            Section {
                Button(locationService.isSharingPaused ? "Resume all sharing" : "Pause all sharing") {
                    locationService.setSharingPaused(!locationService.isSharingPaused)
                }
            } footer: {
                Text("Pausing all sharing overrides every circle below until you resume it. Turning off a single circle only affects that circle.")
            }
        }
        .navigationTitle("Location sharing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sharingBinding(for circleID: String) -> Binding<Bool> {
        Binding(
            get: { locationService.sharingCircleIDs.contains(circleID) },
            set: { newValue in
                pendingCircleID = circleID
                errorMessage = nil
                Task {
                    defer { pendingCircleID = nil }
                    do {
                        try await circleService.setSharingEnabled(newValue, circleID: circleID)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        )
    }
}
