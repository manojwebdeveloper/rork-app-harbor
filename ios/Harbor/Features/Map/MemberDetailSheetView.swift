import SwiftUI

/// Placeholder — layout only. Live coordinates, battery and ETA arrive with the location engine.
struct MemberDetailSheetView: View {
    let member: FirebaseCircleMember

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(.seaGlass))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Text(initials)
                                .font(.headline)
                                .foregroundStyle(Color(.calmTeal))
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(member.displayName)
                            .font(.title3.bold())
                        Text(member.sharingEnabled ? "Sharing is on" : "Sharing is off")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    action("checkmark", "Check in")
                    action("location.fill", "Directions")
                    action("bell", "Notify me")
                    action("ellipsis", "More")
                }

                VStack(spacing: 0) {
                    detailRow("Role", member.role.capitalized)
                    Divider()
                    detailRow("Sharing", member.sharingEnabled ? "On" : "Off")
                    Divider()
                    detailRow(
                        "Joined",
                        member.joinedAt?.formatted(date: .abbreviated, time: .shortened) ?? "—"
                    )
                    Divider()
                    detailRow("Last known", "Not connected yet")
                }
                .padding(.horizontal, 14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))

                Text("Live location is not connected in this build — nothing here is presented as live.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }

    private func action(_ symbol: String, _ title: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption2)
        }
        .foregroundStyle(Color(.calmTeal))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.seaGlass).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
        .padding(.vertical, 12)
    }

    private var initials: String {
        let characters = member.displayName.split(separator: " ").prefix(2).compactMap(\.first)
        let value = String(characters)
        return value.isEmpty ? "H" : value.uppercased()
    }
}
