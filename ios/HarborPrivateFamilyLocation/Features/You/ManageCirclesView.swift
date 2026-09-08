import SwiftUI

/// Real, Firebase-backed multi-circle management — the one circle-management
/// screen in the app. Keeps the Phase 2 card visual design; per-circle detail
/// (invite/leave/delete) is `CircleDetailView`, folded in from the old
/// `CircleManagementView`, which is deleted.
struct ManageCirclesView: View {
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService

    @State private var isShowingNewCircle = false
    @State private var membersByCircleID: [String: [FirebaseCircleMember]] = [:]
    @State private var pendingCircleID: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(sharingCount) of \(circleService.circles.count) circles sharing your location")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                }

                ForEach(circleService.circles) { circle in
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
        .task(id: circleService.circles.map(\.id)) {
            await loadMembers()
        }
    }

    private var sharingCount: Int {
        circleService.circles.filter { locationService.sharingCircleIDs.contains($0.id) }.count
    }

    private func card(for circle: FirebaseCircleSummary) -> some View {
        VStack(spacing: 0) {
            NavigationLink {
                CircleDetailView(circle: circle)
            } label: {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(tint(for: circle).opacity(0.85))
                        .frame(height: 4)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(circle.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.primary)

                                if circle.kind == .trip {
                                    Text("TRIP")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Color(.clearSky))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color(.clearSky).opacity(0.14))
                                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                }
                            }

                            Text("\(members(for: circle).count) people · \(durationText(for: circle))")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 10) {
                            HStack(spacing: -9) {
                                ForEach(Array(members(for: circle).prefix(4).enumerated()), id: \.offset) { index, member in
                                    Circle()
                                        .fill(memberTint(index).opacity(0.16))
                                        .frame(width: 30, height: 30)
                                        .overlay {
                                            Circle().stroke(memberTint(index), lineWidth: 1.5)
                                        }
                                        .overlay {
                                            Text(initials(for: member.displayName))
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(memberTint(index))
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

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
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
                .disabled(pendingCircleID == circle.id)

                if circle.kind == .trip {
                    HStack(spacing: 12) {
                        tripAction("Extend", circleID: circle.id) { Task { await extend(circle) } }
                        tripAction("Keep permanently", circleID: circle.id) { Task { await keepPermanently(circle) } }
                    }
                }
            }
            .padding(16)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 3)
    }

    private func tripAction(_ title: String, circleID: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
        .disabled(pendingCircleID == circleID)
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
            .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                    .strokeBorder(
                        Color(.mineralBorder),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 5])
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private static let tintPalette: [Color] = [Color(.calmTeal), Color(.softCoral), Color(.clearSky), Color(.warmAmber)]

    private func tint(for circle: FirebaseCircleSummary) -> Color {
        guard let index = circleService.circles.firstIndex(where: { $0.id == circle.id }) else { return Color(.calmTeal) }
        return Self.tintPalette[index % Self.tintPalette.count]
    }

    private func memberTint(_ index: Int) -> Color {
        Self.tintPalette[index % Self.tintPalette.count]
    }

    private func initials(for name: String) -> String {
        let letters = name.split(separator: " ").compactMap(\.first).prefix(2)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private func members(for circle: FirebaseCircleSummary) -> [FirebaseCircleMember] {
        membersByCircleID[circle.id] ?? []
    }

    private func durationText(for circle: FirebaseCircleSummary) -> String {
        guard circle.kind == .trip else { return "permanent" }
        guard let expiresAt = circle.expiresAt else { return "Trip circle" }
        return "Ends \(expiresAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private func isSharing(_ circle: FirebaseCircleSummary) -> Bool {
        locationService.sharingCircleIDs.contains(circle.id)
    }

    private func sharingBinding(for circle: FirebaseCircleSummary) -> Binding<Bool> {
        Binding(
            get: { isSharing(circle) },
            set: { newValue in
                pendingCircleID = circle.id
                errorMessage = nil
                Task {
                    defer { pendingCircleID = nil }
                    do {
                        try await circleService.setSharingEnabled(newValue, circleID: circle.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        )
    }

    private func loadMembers() async {
        for circle in circleService.circles where membersByCircleID[circle.id] == nil {
            if let members = try? await circleService.fetchMembers(circleID: circle.id) {
                membersByCircleID[circle.id] = members
            }
        }
    }

    private func extend(_ circle: FirebaseCircleSummary) async {
        pendingCircleID = circle.id
        errorMessage = nil
        defer { pendingCircleID = nil }
        let newExpiry = (circle.expiresAt ?? .now).addingTimeInterval(3 * 24 * 60 * 60)
        do {
            try await circleService.extendTrip(circleID: circle.id, newExpiresAt: newExpiry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func keepPermanently(_ circle: FirebaseCircleSummary) async {
        pendingCircleID = circle.id
        errorMessage = nil
        defer { pendingCircleID = nil }
        do {
            try await circleService.keepCirclePermanently(circleID: circle.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
