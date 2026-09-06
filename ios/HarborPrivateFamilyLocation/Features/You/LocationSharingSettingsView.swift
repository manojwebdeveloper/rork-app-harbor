import SwiftUI

/// Placeholder — layout only. Per-circle sharing toggles arrive with the location engine.
struct LocationSharingSettingsView: View {
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService

    var body: some View {
        List {
            Section("Who can see my location") {
                if circleService.circles.isEmpty {
                    Text("No circles yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(circleService.circles) { circle in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(circle.name)
                            Text(circle.kind.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Active temporary session") {
                Text("No active sharing session")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(locationService.isSharingPaused ? "Resume all sharing" : "Pause all sharing") {
                    locationService.setSharingPaused(!locationService.isSharingPaused)
                }
            } footer: {
                Text("Per-circle sharing controls become active once the location engine is connected.")
            }
        }
        .navigationTitle("Location sharing")
        .navigationBarTitleDisplayMode(.inline)
    }
}
