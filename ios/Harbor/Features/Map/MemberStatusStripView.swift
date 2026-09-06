import SwiftUI

/// The horizontal member strip that sits above the tab bar on the map.
struct MemberStatusStripView: View {
    let members: [SampleMember]
    let selectedMemberID: String?
    let onSelect: (SampleMember) -> Void
    let onSelectAll: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button(action: onSelectAll) {
                    Text("All")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color(.calmTeal))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                ForEach(members) { member in
                    Button {
                        onSelect(member)
                    } label: {
                        chip(for: member)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .contentMargins(.horizontal, 16)
        .scrollClipDisabled()
    }

    private func chip(for member: SampleMember) -> some View {
        HStack(spacing: 9) {
            Circle()
                .fill(member.tint.color.opacity(0.16))
                .frame(width: 34, height: 34)
                .overlay { Circle().stroke(member.tint.color, lineWidth: 1.5) }
                .overlay {
                    Text(member.initials)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(member.tint.color)
                }

            VStack(alignment: .leading, spacing: 1) {
                Text(member.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.primary)

                HStack(spacing: 5) {
                    Text(member.speedText ?? member.place)

                    if let batteryPercent = member.batteryPercent {
                        Text("|")
                            .foregroundStyle(.tertiary)
                        HStack(spacing: 3) {
                            Image(systemName: BatteryGlyph.symbol(for: batteryPercent))
                            Text("\(batteryPercent)%")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(member.isBatteryLow ? Color(.warmAmber) : Color.secondary)
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 9)
        .padding(.trailing, 16)
        .padding(.vertical, 9)
        .background(Color(uiColor: .systemBackground))
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(
                member.id == selectedMemberID
                    ? member.tint.color
                    : Color(.mineralBorder).opacity(0.6),
                lineWidth: member.id == selectedMemberID ? 2 : 0.5
            )
        }
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }
}

/// Shared battery symbol picker so the map, widgets and privacy preview stay consistent.
enum BatteryGlyph {
    static func symbol(for percent: Int) -> String {
        switch percent {
        case ..<15: "battery.0percent"
        case ..<40: "battery.25percent"
        case ..<65: "battery.50percent"
        case ..<90: "battery.75percent"
        default: "battery.100percent"
        }
    }
}
