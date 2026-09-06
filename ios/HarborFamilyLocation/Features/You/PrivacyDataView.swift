import SwiftUI

/// Placeholder — layout only, except the account deletion link which is live.
struct PrivacyDataView: View {
    @State private var isSharingBatteryLevel = true
    @State private var isSharingLowBatteryAlerts = true

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
                LabeledContent("Circle memberships", value: "Firebase")
                LabeledContent("Location sharing", value: "Not connected")
            }

            Section("Your location history") {
                LabeledContent("How long we keep it", value: "No data collected")
                Button("Delete location history now") { }
                    .disabled(true)
            }

            Section("Your account") {
                Button("Export a copy of your data") { }
                    .disabled(true)

                NavigationLink {
                    DeleteAccountView()
                } label: {
                    Text("Delete account")
                        .foregroundStyle(Color(.signalRed))
                }
            }
        }
        .navigationTitle("Privacy & data")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Mirrors the map chip so the setting's effect is obvious.
    private var batteryPreviewChip: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(Color(.warmAmber).opacity(0.16))
                .frame(width: 34, height: 34)
                .overlay { Circle().stroke(Color(.warmAmber), lineWidth: 1.5) }
                .overlay {
                    Text(HarborFamilyLocationSample.you.initials)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(.warmAmber))
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(HarborFamilyLocationSample.you.name)
                    .font(.system(size: 15, weight: .bold))

                HStack(spacing: 5) {
                    Text(HarborFamilyLocationSample.you.place)

                    if isSharingBatteryLevel, let batteryPercent = HarborFamilyLocationSample.you.batteryPercent {
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
    }
}
