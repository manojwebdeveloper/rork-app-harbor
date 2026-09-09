import CoreLocation
@preconcurrency import FirebaseAuth
import SwiftUI
import UIKit

/// The map tab. Circles and members are real, Firestore/Realtime-Database-backed
/// data from `CircleService` and `LiveCircleLocationsService` — see those types
/// for how a `FirebaseCircleSummary`/`FirebaseCircleMember` plus a live RTDB tick
/// become the `SampleCircle`/`SampleMember` view models the Phase 2 subviews expect.
struct MainMapView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService
    @StateObject private var liveLocations = LiveCircleLocationsService(firebaseConfigured: true)
    private let widgetSnapshotWriter: WidgetSnapshotWriting = WidgetSnapshotWriter()

    @State private var selectedMemberID: String?
    @State private var isSwitcherExpanded = false
    @State private var isShowingSafeToast = false
    @State private var isShowingSafeReceipt = false
    @State private var isTripBannerVisible = true
    @State private var isShowingNewCircle = false
    @State private var isSendingSafeBroadcast = false
    @State private var isUpdatingTrip = false
    @State private var errorMessage: String?
    @State private var path: [MapRoute] = []

    private static let mapTintPalette: [SampleTint] = [.teal, .coral, .sky, .amber]

    private enum MapRoute: Hashable {
        case manageCircles
        case digestSettings
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if circleService.circles.isEmpty {
                    emptyState
                } else {
                    mapContent
                }
            }
            .navigationDestination(for: MapRoute.self) { route in
                switch route {
                case .manageCircles:
                    ManageCirclesView()
                case .digestSettings:
                    WeeklyDigestSettingsView()
                }
            }
        }
        .task(id: circleService.selectedCircleID) {
            liveLocations.observe(circleID: circleService.selectedCircleID)
        }
        .onChange(of: allMembers) { _, newMembers in
            guard let circleName = selectedCircle?.name else { return }
            widgetSnapshotWriter.writeSnapshot(circleName: circleName, members: newMembers)
        }
    }

    @ViewBuilder
    private var mapContent: some View {
        ZStack(alignment: .top) {
            MapCanvasView(
                members: pinnedMembers,
                selectedMemberID: selectedMemberID,
                showsRoute: selectedCircle.map { !$0.isTrip } ?? true
            ) { member in
                selectedMemberID = member.id
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar

                locationPermissionBanner

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if isShowingSafeToast, let selectedCircle {
                    SafeBroadcastToast(circleName: selectedCircle.name) {
                        isShowingSafeReceipt = true
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let selectedCircle, selectedCircle.isTrip, isTripBannerVisible, isEndingSoon {
                    TripEndingBanner(
                        circleName: selectedCircle.name,
                        onExtend: { Task { await extendTrip() } },
                        onKeepPermanently: { Task { await keepPermanently() } },
                        onLetItEnd: dismissTripBanner
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if isSwitcherExpanded {
                    CircleSwitcherMenu(
                        circles: mappedCircles,
                        selectedCircleID: circleService.selectedCircleID ?? "",
                        onSelect: { select($0.id) },
                        onManage: {
                            collapseSwitcher()
                            path.append(.manageCircles)
                        },
                        onNewCircle: {
                            collapseSwitcher()
                            isShowingNewCircle = true
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            VStack(spacing: 14) {
                Spacer()

                SafeBroadcastButton(action: broadcastSafe)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .disabled(isSendingSafeBroadcast)

                MemberStatusStripView(
                    members: allMembers,
                    selectedMemberID: selectedMemberID,
                    onSelect: { selectedMemberID = $0.id },
                    onSelectAll: { selectedMemberID = nil }
                )
                .padding(.bottom, 96)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: sheetBinding) {
            if let member = allMembers.first(where: { $0.id == selectedMemberID }) {
                MemberStatusSheetView(member: member) {
                    selectedMemberID = nil
                }
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
            }
        }
        .sheet(isPresented: $isShowingNewCircle) {
            NewCircleFlowView { isShowingNewCircle = false }
        }
        .fullScreenCover(isPresented: $isShowingSafeReceipt) {
            CircleActivityPreviewView {
                isShowingSafeReceipt = false
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color(.calmTeal))
            Text("No circles yet")
                .font(.title3.bold())
            Text("Create a family or trip circle, or join one with an invitation code, to see everyone on the map.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            PrimaryButton(title: "New circle") {
                isShowingNewCircle = true
            }
            .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $isShowingNewCircle) {
            NewCircleFlowView { isShowingNewCircle = false }
        }
    }

    private var sheetBinding: Binding<Bool> {
        Binding(
            get: { selectedMemberID != nil },
            set: { if !$0 { selectedMemberID = nil } }
        )
    }

    private var selectedCircle: SampleCircle? {
        mappedCircles.first { $0.id == circleService.selectedCircleID }
    }

    /// Every real, non-owner-excluded member of the selected circle, merged with
    /// their live RTDB location tick when one exists.
    private var allMembers: [SampleMember] {
        circleService.members.enumerated().map { index, member in
            makeSampleMember(member, tint: Self.mapTintPalette[index % Self.mapTintPalette.count])
        }
    }

    /// Only members who have actually published a coordinate — a pin needs
    /// somewhere real to sit, unlike the status strip which can show "waiting".
    private var pinnedMembers: [SampleMember] {
        allMembers.filter { liveLocations.locationsByUserID[$0.id] != nil }
    }

    private var isEndingSoon: Bool {
        guard let expiresAt = circleService.circles.first(where: { $0.id == circleService.selectedCircleID })?.expiresAt else {
            return false
        }
        return expiresAt.timeIntervalSinceNow <= 24 * 60 * 60
    }

    private var mappedCircles: [SampleCircle] {
        circleService.circles.enumerated().map { index, circle in
            SampleCircle(
                id: circle.id,
                name: circle.name,
                tint: Self.mapTintPalette[index % Self.mapTintPalette.count],
                memberCount: circle.id == circleService.selectedCircleID ? circleService.members.count : nil,
                isTrip: circle.kind == .trip,
                durationText: durationText(for: circle),
                memberInitials: [],
                memberTints: []
            )
        }
    }

    private func durationText(for circle: FirebaseCircleSummary) -> String {
        guard circle.kind == .trip else { return "permanent" }
        guard let expiresAt = circle.expiresAt else { return "Trip circle" }
        return "Ends \(expiresAt.formatted(date: .abbreviated, time: .shortened))"
    }

    private func makeSampleMember(_ member: FirebaseCircleMember, tint: SampleTint) -> SampleMember {
        let live = liveLocations.locationsByUserID[member.id]
        let name = member.displayName(asViewedBy: authService.user?.uid)
        return SampleMember(
            id: member.id,
            name: name,
            initials: initials(for: name),
            tint: tint,
            presence: presence(for: member, live: live),
            place: member.sharingEnabled ? (live == nil ? "Waiting for location" : "Live") : "Sharing paused",
            statusDetail: statusDetail(for: member, live: live),
            batteryPercent: live?.batteryLevel,
            speedText: speedText(for: live),
            isDriving: (live?.speed ?? 0) > 3,
            address: live.map { String(format: "%.4f, %.4f", $0.coordinate.latitude, $0.coordinate.longitude) }
                ?? "No location shared yet",
            lastUpdate: lastUpdateText(for: live),
            accuracy: live?.horizontalAccuracy.map { "Within \(Int($0)) m" } ?? "Unknown",
            sharing: member.sharingEnabled ? "Sharing now" : "Sharing paused",
            coordinate: live?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
            isSelf: member.id == authService.user?.uid
        )
    }

    private func presence(for member: FirebaseCircleMember, live: LiveCircleLocationsService.LiveLocation?) -> SamplePresence {
        guard member.sharingEnabled else { return .stopped }
        guard let live else { return .stopped }
        if let battery = live.batteryLevel, battery <= 20 { return .needsAttention }
        let age = Date().timeIntervalSince(live.updatedAt)
        if age <= 5 * 60 { return .upToDate }
        if age <= 30 * 60 { return .needsAttention }
        return .stopped
    }

    private func statusDetail(for member: FirebaseCircleMember, live: LiveCircleLocationsService.LiveLocation?) -> String {
        guard member.sharingEnabled else { return "Sharing paused" }
        guard live != nil else { return "Waiting for a location update" }
        return lastUpdateText(for: live)
    }

    private func speedText(for live: LiveCircleLocationsService.LiveLocation?) -> String? {
        guard let speed = live?.speed, speed > 1 else { return nil }
        return String(format: "%.0f mph", speed * 2.23694)
    }

    private func initials(for name: String) -> String {
        let letters = name.split(separator: " ").compactMap(\.first).prefix(2)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private func lastUpdateText(for live: LiveCircleLocationsService.LiveLocation?) -> String {
        guard let live else { return "No updates yet" }
        if Date().timeIntervalSince(live.updatedAt) < 30 { return "Live now" }
        return Self.relativeFormatter.localizedString(for: live.updatedAt, relativeTo: Date())
    }

    /// Previously there was no UI signal at all when location access was
    /// never granted or was denied — the member sheet just said "Waiting
    /// for a location update" forever with nothing explaining why, and no
    /// way back in if onboarding's permission step was skipped.
    @ViewBuilder
    private var locationPermissionBanner: some View {
        switch locationService.authorizationStatus {
        case .notDetermined:
            permissionBanner(
                message: "Turn on location to share your position with this circle.",
                actionTitle: "Allow Location Access"
            ) {
                locationService.requestWhenInUseAuthorization()
            }
        case .denied, .restricted:
            permissionBanner(
                message: "Location access is off, so your own position can't be shared.",
                actionTitle: "Open Settings"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        default:
            EmptyView()
        }
    }

    private func permissionBanner(message: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "location.slash")
                .foregroundStyle(Color(.warmAmber))
            Text(message)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(actionTitle, action: action)
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(Color(.calmTeal))
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                appState.selectedTab = .you
            } label: {
                Circle()
                    .fill(Color(.warmAmber).opacity(0.16))
                    .frame(width: 42, height: 42)
                    .overlay { Circle().stroke(Color(.warmAmber), lineWidth: 2) }
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(.warmAmber))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your profile")

            Spacer(minLength: 0)

            if let selectedCircle {
                CircleSelectorPill(circle: selectedCircle, isExpanded: isSwitcherExpanded) {
                    withAnimation(.snappy(duration: 0.25)) {
                        isSwitcherExpanded.toggle()
                    }
                }
            }

            Spacer(minLength: 0)

            Button {
                path.append(.digestSettings)
            } label: {
                Image(systemName: "bell")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 42, height: 42)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notification settings")
        }
    }

    private func select(_ circleID: String) {
        withAnimation(.snappy(duration: 0.25)) {
            circleService.selectCircle(circleID)
            isSwitcherExpanded = false
            isTripBannerVisible = true
            selectedMemberID = nil
        }
    }

    private func collapseSwitcher() {
        withAnimation(.snappy(duration: 0.25)) {
            isSwitcherExpanded = false
        }
    }

    private func dismissTripBanner() {
        withAnimation(.snappy(duration: 0.3)) {
            isTripBannerVisible = false
        }
    }

    private func broadcastSafe() {
        guard let circleID = circleService.selectedCircleID else { return }
        isSendingSafeBroadcast = true
        Task {
            defer { isSendingSafeBroadcast = false }
            do {
                try await circleService.sendSafeBroadcast(circleID: circleID)
                withAnimation(.snappy(duration: 0.3)) {
                    isSwitcherExpanded = false
                    isShowingSafeToast = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func extendTrip() async {
        guard let circleID = circleService.selectedCircleID,
              let currentExpiry = circleService.circles.first(where: { $0.id == circleID })?.expiresAt else { return }
        isUpdatingTrip = true
        defer { isUpdatingTrip = false }
        do {
            try await circleService.extendTrip(circleID: circleID, newExpiresAt: currentExpiry.addingTimeInterval(3 * 24 * 60 * 60))
            dismissTripBanner()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func keepPermanently() async {
        guard let circleID = circleService.selectedCircleID else { return }
        isUpdatingTrip = true
        defer { isUpdatingTrip = false }
        do {
            try await circleService.keepCirclePermanently(circleID: circleID)
            dismissTripBanner()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
