import CoreLocation
@preconcurrency import FirebaseAuth
import SwiftUI
import UIKit

/// The map tab. Circles and members are real, Firestore/Realtime-Database-backed
/// data from `CircleService` and `LiveCircleLocationsService` — see those types
/// for how a `FirebaseCircleSummary`/`FirebaseCircleMember` plus a live RTDB tick
/// become the `SampleCircle`/`SampleMember` view models the Phase 2 subviews expect.
struct MainMapView: View {
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
    @State private var isShowingInvite = false
    @State private var errorMessage: String?
    @State private var path: [MapRoute] = []
    @State private var hasRequestedAlwaysAuthorization = false

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

                if let selectedCircle, selectedCircle.isTrip, isTripBannerVisible,
                   let expiresAt = selectedFirebaseCircle?.expiresAt, isEndingSoon(expiresAt) {
                    TripEndingBanner(
                        circleName: selectedCircle.name,
                        expiresAt: expiresAt,
                        isOwner: selectedFirebaseCircle?.role == "owner",
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
                    members: otherMembers,
                    selectedMemberID: selectedMemberID,
                    onSelect: { selectedMemberID = $0.id },
                    onSelectAll: { selectedMemberID = nil },
                    onAddMember: { isShowingInvite = true }
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
        .sheet(isPresented: $isShowingInvite) {
            NavigationStack {
                InviteView(circleID: circleService.selectedCircleID ?? "")
            }
            .environmentObject(circleService)
        }
        .fullScreenCover(isPresented: $isShowingSafeReceipt) {
            CircleActivityPreviewView {
                isShowingSafeReceipt = false
            }
        }
        .onAppear { requestAlwaysAuthorizationIfNeeded() }
    }

    /// Apple's own guidance (and App Review) expects the "Always" upgrade to
    /// arrive as a distinct follow-up once the user actually understands why
    /// background sharing matters — never immediately back-to-back with the
    /// "When In Use" prompt onboarding already asks for, since iOS itself
    /// tends to silently no-op a second request fired too soon after the
    /// first. Landing on the map with a real circle already in place (this
    /// view only renders once `circleService.circles` is non-empty — see
    /// `body`) is that moment: the user has just gone from "setting up" to
    /// "about to actually share with people", which is exactly when sharing
    /// while backgrounded starts to matter. A no-op unless the user is
    /// still sitting at plain "When In Use" — already-Always, denied, and
    /// not-yet-determined are all left alone, and `hasRequestedAlwaysAuthorization`
    /// keeps this to once per app session rather than re-asking every time
    /// the tab reappears.
    private func requestAlwaysAuthorizationIfNeeded() {
        guard !hasRequestedAlwaysAuthorization,
              locationService.authorizationStatus == .authorizedWhenInUse else { return }
        hasRequestedAlwaysAuthorization = true
        locationService.requestAlwaysAuthorization()
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

    /// The bottom carousel is "everyone but me" — the current user already
    /// sees themselves via their own map marker, so per design they don't
    /// get a redundant chip in their own member list.
    private var otherMembers: [SampleMember] {
        allMembers.filter { !$0.isSelf }
    }

    /// The real Firestore-backed circle behind `selectedCircle` — the single
    /// source both the header's "Ends ..." text and the trip-ending banner
    /// must read `expiresAt` (and the current user's `role`) from, so the
    /// two can never disagree about when the circle actually closes.
    private var selectedFirebaseCircle: FirebaseCircleSummary? {
        circleService.circles.first { $0.id == circleService.selectedCircleID }
    }

    private func isEndingSoon(_ expiresAt: Date) -> Bool {
        expiresAt.timeIntervalSinceNow <= 24 * 60 * 60
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
        let presence = presence(for: member, live: live)
        return SampleMember(
            id: member.id,
            name: name,
            initials: initials(for: name),
            tint: tint,
            presence: presence,
            place: member.sharingEnabled ? (live == nil ? "Waiting for location" : "Live") : "Sharing paused",
            statusDetail: statusDetail(for: member, live: live),
            batteryPercent: live?.batteryLevel,
            speedText: speedText(for: live),
            isDriving: (live?.speed ?? 0) > 3,
            address: live.map { String(format: "%.4f, %.4f", $0.coordinate.latitude, $0.coordinate.longitude) }
                ?? "No location shared yet",
            lastUpdate: lastUpdateText(for: live),
            accuracy: live?.horizontalAccuracy.map { "Within \(Int($0)) m" } ?? "Unknown",
            sharing: sharingText(for: member, presence: presence, live: live),
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

    /// The detail sheet's "Sharing" row was previously just `sharingEnabled
    /// ? "Sharing now" : "Sharing paused"` — completely independent of the
    /// same staleness signal driving the presence dot right above it, so a
    /// member stuck on a 2-day-old location (a red/`.stopped` dot) still
    /// read "Sharing now" a few rows down. Deriving it from `presence`
    /// instead means the two can never contradict each other again.
    private func sharingText(
        for member: FirebaseCircleMember,
        presence: SamplePresence,
        live: LiveCircleLocationsService.LiveLocation?
    ) -> String {
        guard member.sharingEnabled else { return "Sharing paused" }
        guard presence != .stopped else {
            guard let live else { return "Waiting for location" }
            return "Last seen \(lastUpdateText(for: live))"
        }
        return "Sharing now"
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
              let currentExpiry = selectedFirebaseCircle?.expiresAt else { return }
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
