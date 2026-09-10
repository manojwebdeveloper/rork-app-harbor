import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var activityService: ActivityService

    @State private var isCheckingIn = false
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    NavigationLink {
                        WeeklyDigestView()
                    } label: {
                        digestCard
                    }
                    .buttonStyle(.plain)

                    Text("TODAY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    if timelineEntries.isEmpty {
                        Text("Nothing yet today.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ActivityTimelineView(entries: timelineEntries)
                    }

                    Text("Activity is visible only to your circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 130)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isCheckingIn) {
                if let circleID = circleService.selectedCircleID {
                    CheckInSheetView(circleID: circleID) {
                        isCheckingIn = false
                        showingConfirmation = true
                    }
                    .presentationDetents([.medium, .large])
                    .presentationContentInteraction(.scrolls)
                }
            }
            .overlay {
                if showingConfirmation {
                    CheckInConfirmationView {
                        showingConfirmation = false
                    }
                }
            }
        }
    }

    private var timelineEntries: [SampleActivityEntry] {
        ActivityTimelineMapping.entries(
            checkIns: activityService.checkIns,
            serverActivity: activityService.serverActivity,
            members: circleService.members
        )
    }

    // A custom header, not `.navigationTitle` + `.toolbar` — iOS 26 collapses
    // ordinary toolbar items to an icon-only glass circle regardless of
    // label style or placement, which drops the "Check in" text the design
    // keeps. Drawing the row ourselves (same approach MainMapView's topBar
    // already uses) sidesteps that and lets a real `harborGlass` pill work,
    // since this is a view the app draws, not a system-provided toolbar.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Activity")
                .font(.system(size: 34, weight: .bold))
            Spacer(minLength: 0)
            checkInButton
        }
    }

    private var checkInButton: some View {
        Button {
            isCheckingIn = true
        } label: {
            Label("Check in", systemImage: "checkmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.calmTeal))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                // No tint: the design's chip is a pale, muted glass surface
                // with dark teal text, not a saturated fill — unlike
                // SafeBroadcastButton, which is solid-teal with white text.
                // Tinting this one teal would wash out the teal text on top.
                .harborGlass(in: Capsule(), fallback: Color(.seaGlass))
        }
        .buttonStyle(.plain)
        .disabled(circleService.selectedCircleID == nil)
    }

    private var digestCard: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(.seaGlass))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(.calmTeal))
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("Your week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primary)
                Text(digestSummaryText)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5)
        }
    }

    private var digestSummaryText: String {
        guard let digest = activityService.latestDigest else {
            return "No digest yet — check back after your first week"
        }
        let totalCheckIns = digest.memberSummaries.reduce(0) { $0 + $1.checkIns }
        let totalPlaces = digest.memberSummaries.reduce(0) { $0 + $1.places }
        return "\(totalCheckIns) check-ins, \(totalPlaces) places"
    }
}
