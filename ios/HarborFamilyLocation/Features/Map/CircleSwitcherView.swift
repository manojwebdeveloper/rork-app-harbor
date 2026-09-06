import SwiftUI

/// The circle pill at the top of the map.
struct CircleSelectorPill: View {
    let circle: SampleCircle
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if circle.isTrip {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.clearSky).opacity(0.16))
                        .frame(width: 28, height: 28)
                        .overlay {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(.clearSky))
                        }
                }

                VStack(spacing: 1) {
                    Text(circle.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.primary)

                    if circle.isTrip {
                        Text(circle.durationText)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, circle.isTrip ? 8 : 12)
            .background(Color(uiColor: .systemBackground))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 14, y: 4)
        }
        .buttonStyle(.plain)
    }
}

/// The dropdown that lists every circle plus the management entry points.
struct CircleSwitcherMenu: View {
    let circles: [SampleCircle]
    let selectedCircleID: String
    let onSelect: (SampleCircle) -> Void
    let onManage: () -> Void
    let onNewCircle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(circles) { circle in
                Button {
                    onSelect(circle)
                } label: {
                    row(for: circle)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 68)
            }

            Button(action: onManage) {
                actionRow(symbol: "sparkles", title: "Manage circles")
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 44)

            Button(action: onNewCircle) {
                actionRow(symbol: "plus", title: "New circle")
            }
            .buttonStyle(.plain)
        }
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.field, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 22, y: 8)
    }

    private func row(for circle: SampleCircle) -> some View {
        HStack(spacing: 13) {
            if circle.isTrip {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.clearSky).opacity(0.16))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(.clearSky))
                    }
            } else {
                Circle()
                    .fill(circle.tint.color.opacity(0.16))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Circle()
                            .fill(circle.tint.color)
                            .frame(width: 11, height: 11)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 7) {
                    Text(circle.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.primary)

                    if circle.isTrip {
                        Text("TRIP")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(.clearSky))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.clearSky).opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                }

                Text(subtitle(for: circle))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if circle.id == selectedCircleID {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(.calmTeal))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            circle.id == selectedCircleID
                ? Color(uiColor: .secondarySystemFill).opacity(0.5)
                : Color.clear
        )
        .contentShape(Rectangle())
    }

    private func subtitle(for circle: SampleCircle) -> String {
        circle.isTrip
            ? circle.durationText
            : "\(circle.memberCount) people · sharing"
    }

    private func actionRow(symbol: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(.calmTeal))
                .frame(width: 20)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(.calmTeal))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
