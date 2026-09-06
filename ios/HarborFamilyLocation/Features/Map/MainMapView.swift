import SwiftUI

/// The map tab, built to the Phase 2 design.
///
/// The map canvas, pins and member strip are populated with static placeholder people
/// (`HarborFamilyLocationSample`) because the location engine does not exist yet. Circle management
/// still routes to the live Firebase screens from the You tab.
struct MainMapView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selectedCircleID: String = HarborFamilyLocationSample.circles[0].id
    @State private var selectedMember: SampleMember?
    @State private var isSwitcherExpanded = false
    @State private var isShowingSafeToast = false
    @State private var isShowingSafeReceipt = false
    @State private var isTripBannerVisible = true
    @State private var isShowingNewCircle = false
    @State private var path: [MapRoute] = []

    private enum MapRoute: Hashable {
        case manageCircles
        case digestSettings
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                MapCanvasView(
                    members: members,
                    selectedMemberID: selectedMember?.id,
                    showsRoute: !selectedCircle.isTrip
                ) { member in
                    selectedMember = member
                }
                .ignoresSafeArea()

                mapControls

                VStack(spacing: 12) {
                    topBar

                    if isShowingSafeToast {
                        SafeBroadcastToast(circleName: selectedCircle.name) {
                            isShowingSafeReceipt = true
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if selectedCircle.isTrip && isTripBannerVisible {
                        TripEndingBanner(
                            circleName: selectedCircle.name,
                            onExtend: dismissTripBanner,
                            onKeepPermanently: dismissTripBanner,
                            onLetItEnd: dismissTripBanner
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if isSwitcherExpanded {
                        CircleSwitcherMenu(
                            circles: HarborFamilyLocationSample.circles,
                            selectedCircleID: selectedCircleID,
                            onSelect: select,
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

                    MemberStatusStripView(
                        members: members,
                        selectedMemberID: selectedMember?.id,
                        onSelect: { selectedMember = $0 },
                        onSelectAll: { selectedMember = nil }
                    )
                    .padding(.bottom, 96)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MapRoute.self) { route in
                switch route {
                case .manageCircles:
                    ManageCirclesView()
                case .digestSettings:
                    WeeklyDigestSettingsView()
                }
            }
        }
        .sheet(item: $selectedMember) { member in
            MemberStatusSheetView(member: member) {
                selectedMember = nil
            }
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
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

    private var selectedCircle: SampleCircle {
        HarborFamilyLocationSample.circles.first { $0.id == selectedCircleID } ?? HarborFamilyLocationSample.circles[0]
    }

    private var members: [SampleMember] {
        selectedCircle.isTrip ? HarborFamilyLocationSample.tripMembers : HarborFamilyLocationSample.members
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
                        Text(HarborFamilyLocationSample.you.initials)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(.warmAmber))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your profile")

            Spacer(minLength: 0)

            CircleSelectorPill(circle: selectedCircle, isExpanded: isSwitcherExpanded) {
                withAnimation(.snappy(duration: 0.25)) {
                    isSwitcherExpanded.toggle()
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

    private var mapControls: some View {
        VStack(spacing: 10) {
            mapControl("location.viewfinder")
            mapControl("location.north.fill")
            mapControl("square.3.layers.3d")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.trailing, 16)
        .padding(.top, 96)
        .allowsHitTesting(true)
    }

    private func mapControl(_ symbol: String) -> some View {
        Button { } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 42, height: 42)
                .background(Color(uiColor: .systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 10, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func select(_ circle: SampleCircle) {
        withAnimation(.snappy(duration: 0.25)) {
            selectedCircleID = circle.id
            isSwitcherExpanded = false
            isTripBannerVisible = true
            selectedMember = nil
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
        withAnimation(.snappy(duration: 0.3)) {
            isSwitcherExpanded = false
            isShowingSafeToast = true
        }
    }
}
