import SwiftUI

/// Phase 2 multi-circle management. Layout only — the toggles and trip actions
/// hold local state and never reach a backend.
struct ManageCirclesView: View {
    @State private var sharingByCircleID: [String: Bool] = Dictionary(
        uniqueKeysWithValues: HarborFamilyLocationSample.circles.map { ($0.id, true) }
    )
    @State private var isShowingNewCircle = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(sharingCount) of \(HarborFamilyLocationSample.circles.count) circles sharing your location")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                ForEach(HarborFamilyLocationSample.circles) { circle in
                    card(for: circle)
                }

                newCircleCard

                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "shield")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("Pausing one circle affects only that circle. The others keep sharing exactly as before, and each circle only ever sees its own members.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Your circles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingNewCircle) {
            NewCircleFlowView { isShowingNewCircle = false }
        }
    }

    private var sharingCount: Int {
        sharingByCircleID.values.filter { $0 }.count
    }

    private func card(for circle: SampleCircle) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(circle.tint.color)
                .frame(height: 4)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(circle.name)
                            .font(.system(size: 18, weight: .bold))

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

                    Text("\(circle.memberCount) people · \(circle.durationText)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    HStack(spacing: -9) {
                        ForEach(Array(circle.memberInitials.enumerated()), id: \.offset) { index, initial in
                            Circle()
                                .fill(tint(at: index, in: circle).opacity(0.16))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Circle().stroke(tint(at: index, in: circle), lineWidth: 1.5)
                                }
                                .overlay {
                                    Text(initial)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(tint(at: index, in: circle))
                                }
                        }
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isSharing(circle) ? Color(.safeGreen) : Color(.slate))
                            .frame(width: 7, height: 7)
                        Text(isSharing(circle)
                             ? "You are sharing with this circle"
                             : "Sharing paused for this circle")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }

                Divider()

                Toggle(isOn: sharingBinding(for: circle)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share my location here")
                            .font(.system(size: 15, weight: .bold))
                        Text("Only this circle. Others are unaffected.")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(Color(.safeGreen))

                if circle.isTrip {
                    HStack(spacing: 12) {
                        tripAction("Extend")
                        tripAction("Keep permanently")
                    }
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 3)
    }

    private func tripAction(_ title: String) -> some View {
        Button { } label: {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(.calmTeal))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(uiColor: .systemBackground))
                .clipShape(Capsule())
                .overlay { Capsule().stroke(Color(.mineralBorder), lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }

    private var newCircleCard: some View {
        Button {
            isShowingNewCircle = true
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(.seaGlass))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(.calmTeal))
                    }

                Text("New circle")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(.calmTeal))

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous)
                    .strokeBorder(
                        Color(.mineralBorder),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 5])
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func tint(at index: Int, in circle: SampleCircle) -> Color {
        guard index < circle.memberTints.count else { return Color(.slate) }
        return circle.memberTints[index].color
    }

    private func isSharing(_ circle: SampleCircle) -> Bool {
        sharingByCircleID[circle.id] ?? true
    }

    private func sharingBinding(for circle: SampleCircle) -> Binding<Bool> {
        Binding(
            get: { sharingByCircleID[circle.id] ?? true },
            set: { sharingByCircleID[circle.id] = $0 }
        )
    }
}
