import SwiftUI

struct MainMapView: View {
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var locationService: LocationService

    @State private var selectedMember: FirebaseCircleMember?

    var body: some View {
        NavigationStack {
            Group {
                if circleService.isLoading {
                    loadingState
                } else if let circle = circleService.selectedCircle {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            CircleSelectorView(selected: circle)

                            if !locationService.isAuthorized {
                                permissionBanner
                            } else if locationService.isSharingPaused {
                                pausedBanner
                            }

                            mapPlaceholder(circle: circle)

                            MemberCarouselView(
                                members: circleService.members,
                                selectedMemberID: selectedMember?.id
                            ) { member in
                                selectedMember = member
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 130)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                } else {
                    noCircleState
                }
            }
            .navigationTitle("Map")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CircleManagementView()
                    } label: {
                        Image(systemName: "person.3")
                    }
                }
            }
        }
        .sheet(item: $selectedMember) { member in
            MemberDetailSheetView(member: member)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Finding your circle…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var permissionBanner: some View {
        banner(
            symbol: "location.slash.fill",
            tint: Color(.warmAmber),
            title: "Location access is off",
            detail: "Harbor can't share your location with your circle."
        )
    }

    private var pausedBanner: some View {
        banner(
            symbol: "pause.circle.fill",
            tint: Color(.slate),
            title: "Your location sharing is paused",
            detail: "Your circle sees your last shared location."
        )
    }

    private func banner(
        symbol: String,
        tint: Color,
        title: String,
        detail: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .harborCard()
    }

    private func mapPlaceholder(circle: FirebaseCircleSummary) -> some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.seaGlass).opacity(0.55))
                    .frame(height: 210)

                VStack(spacing: 13) {
                    Image(systemName: "location.slash.fill")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(Color(.calmTeal))
                    Text("Real location sharing is not connected yet")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    Text("This screen is using your real Firebase circle and members. No sample coordinates are being shown.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                }
            }

            HStack {
                Label("\(circleService.members.count) members", systemImage: "person.2.fill")
                Spacer()
                if let expiresAt = circle.expiresAt {
                    Label(expiresAt.formatted(date: .abbreviated, time: .shortened), systemImage: "timer")
                } else {
                    Label("No expiry", systemImage: "infinity")
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .harborCard()
    }

    private var noCircleState: some View {
        ContentUnavailableView {
            Label("Create or join a circle", systemImage: "person.3.sequence.fill")
        } description: {
            Text("Your real Firebase circles will appear here. Harbor does not insert sample families into signed-in accounts.")
        } actions: {
            NavigationLink("Manage circles") {
                CircleManagementView()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
