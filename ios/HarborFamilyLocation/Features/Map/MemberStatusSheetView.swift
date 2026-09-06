import SwiftUI

/// Member detail sheet with the Phase 2 driving and low-battery states.
/// Layout only — nothing here reads a real sensor, speed or battery level.
struct MemberStatusSheetView: View {
    let member: SampleMember
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if member.isDriving {
                    drivingCard
                } else if member.isBatteryLow {
                    lowBatteryCard
                }

                actionRow
                detailCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 30)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(member.tint.color.opacity(0.16))
                .frame(width: 58, height: 58)
                .overlay { Circle().stroke(member.tint.color, lineWidth: 2) }
                .overlay {
                    Text(member.initials)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundStyle(member.tint.color)
                }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 9) {
                    Text(member.name)
                        .font(.system(size: 26, weight: .bold))

                    if let batteryPercent = member.batteryPercent {
                        batteryPill(batteryPercent)
                    }
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(member.isDriving ? Color(.clearSky) : member.presence.color)
                        .frame(width: 7, height: 7)
                    Text(member.statusDetail)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(uiColor: .secondarySystemFill))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    private func batteryPill(_ percent: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: BatteryGlyph.symbol(for: percent))
            Text("\(percent)%")
                .fontWeight(.semibold)
        }
        .font(.system(size: 12))
        .foregroundStyle(member.isBatteryLow ? Color(.warmAmber) : Color.secondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            (member.isBatteryLow ? Color(.warmAmber) : Color(.slate)).opacity(0.14)
        )
        .clipShape(Capsule())
    }

    private var drivingCard: some View {
        statusCard(
            symbol: "car.fill",
            tint: Color(.clearSky),
            title: "Driving · \(member.speedText ?? "")",
            detail: "On the road 18 min · started 4:12 PM",
            isWarning: false
        )
    }

    private var lowBatteryCard: some View {
        statusCard(
            symbol: "battery.25percent",
            tint: Color(.warmAmber),
            title: "Battery is low",
            detail: "\(member.name)’s location may stop updating if her phone turns off.",
            isWarning: true
        )
    }

    private func statusCard(
        symbol: String,
        tint: Color,
        title: String,
        detail: String,
        isWarning: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 13) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint.opacity(0.16))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            isWarning
                ? Color(.warmAmber).opacity(0.1)
                : Color(uiColor: .secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.field, style: .continuous))
        .overlay {
            if isWarning {
                RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.field, style: .continuous)
                    .stroke(Color(.warmAmber).opacity(0.5), lineWidth: 1)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            action("checkmark", "Check in")
            action("arrow.triangle.turn.up.right.diamond.fill", "Directions")
            action("bell.fill", "Notify me")
            action("ellipsis", "More")
        }
    }

    private func action(_ symbol: String, _ title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Color(.calmTeal))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.6), lineWidth: 0.5)
        }
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            detailRow("Location", member.address)
            Divider()
            detailRow("Last update", member.lastUpdate)
            Divider()
            detailRow("Accuracy", member.accuracy)
            Divider()
            detailRow("Sharing", member.sharing)

            if let batteryPercent = member.batteryPercent {
                Divider()
                detailRow("Battery", "\(batteryPercent)%")
            }

            Divider()

            Text(footnote)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
    }

    private var footnote: String {
        member.isDriving
            ? "Speed comes from his phone’s motion sensors, not tracking hardware."
            : "Live location · end-to-end encrypted"
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 15))
        .padding(.vertical, 12)
    }
}
