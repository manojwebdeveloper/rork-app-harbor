import SwiftUI

/// "As Maya sees it" — what the circle's Activity list looks like after a safe broadcast.
/// Layout only, driven by static placeholder entries.
struct CircleActivityPreviewView: View {
    let onBackToMap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.system(size: 34, weight: .bold))
                Text("As Maya sees it, on her phone")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Text("TODAY")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 10)

            ActivityTimelineView(entries: HarborFamilyLocationSample.activityAsCircleSeesIt)
                .padding(.horizontal, 20)

            Spacer()

            Button(action: onBackToMap) {
                Text("Back to the map")
                    .font(.headline)
                    .foregroundStyle(Color(.calmTeal))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous)
                            .stroke(Color(.mineralBorder), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

/// Shared timeline used by the Activity tab and the circle preview.
struct ActivityTimelineView: View {
    let entries: [SampleActivityEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: 12) {
                    Text(entry.time)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)

                    VStack(spacing: 0) {
                        Circle()
                            .stroke(entry.tint.color, lineWidth: 2.5)
                            .frame(width: 11, height: 11)
                            .padding(.top, 5)

                        Rectangle()
                            .fill(Color(.mineralBorder))
                            .frame(width: 1)
                            .opacity(index == entries.count - 1 ? 0 : 1)
                    }
                    .frame(width: 11)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(entry.title)
                                .font(.system(size: 16, weight: .bold))

                            if let badge = entry.badge {
                                Text(badge)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(.calmTeal))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color(.seaGlass))
                                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            }
                        }

                        Text(entry.detail)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 22)

                    Spacer(minLength: 0)
                }
            }
        }
    }
}
