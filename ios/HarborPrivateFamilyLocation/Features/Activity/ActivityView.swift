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
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCheckingIn = true
                    } label: {
                        Label("Check in", systemImage: "checkmark")
                            .font(.caption.weight(.semibold))
                    }
                    .disabled(circleService.selectedCircleID == nil)
                }
            }
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
