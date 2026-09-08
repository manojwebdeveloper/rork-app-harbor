import SwiftUI

struct WeeklyDigestView: View {
    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var activityService: ActivityService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let digest = activityService.latestDigest {
                    Text("\(dateRangeText(digest)) · \(circleService.selectedCircle?.name ?? "Your circle")")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        statTile(value: "\(totalCheckIns(digest))", label: "check-ins sent")
                        statTile(value: "\(totalPlaces(digest))", label: "places visited")
                        statTile(value: "\(totalAlerts(digest))", label: "Smart Alerts")
                    }
                    .padding(.top, 14)

                    Text("BY MEMBER")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 26)
                        .padding(.bottom, 12)

                    VStack(spacing: 14) {
                        ForEach(digest.memberSummaries) { summary in
                            memberCard(summary)
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("No digest yet", systemImage: "calendar")
                    } description: {
                        Text("Your first weekly digest appears after your circle's first full week together.")
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Your week")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func totalCheckIns(_ digest: DigestSummary) -> Int { digest.memberSummaries.reduce(0) { $0 + $1.checkIns } }
    private func totalPlaces(_ digest: DigestSummary) -> Int { digest.memberSummaries.reduce(0) { $0 + $1.places } }
    private func totalAlerts(_ digest: DigestSummary) -> Int { digest.memberSummaries.reduce(0) { $0 + $1.alerts } }

    private func dateRangeText(_ digest: DigestSummary) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: digest.weekStart)) – \(formatter.string(from: digest.weekEnd))"
    }

    private func memberName(_ userID: String) -> String {
        circleService.members.first { $0.id == userID }?.displayName ?? "Circle member"
    }

    private func memberInitials(_ userID: String) -> String {
        let name = memberName(userID)
        let letters = name.split(separator: " ").compactMap(\.first).prefix(2)
        return letters.isEmpty ? "?" : String(letters).uppercased()
    }

    private func memberTint(_ userID: String) -> Color {
        let palette: [Color] = [Color(.clearSky), Color(.calmTeal), Color(.softCoral), Color(.warmAmber)]
        guard let index = circleService.members.firstIndex(where: { $0.id == userID }) else { return Color(.calmTeal) }
        return palette[index % palette.count]
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5)
        }
    }

    private func memberCard(_ summary: DigestSummary.MemberSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(memberTint(summary.userID).opacity(0.16))
                    .frame(width: 40, height: 40)
                    .overlay { Circle().stroke(memberTint(summary.userID), lineWidth: 2) }
                    .overlay {
                        Text(memberInitials(summary.userID))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(memberTint(summary.userID))
                    }

                Text(memberName(summary.userID))
                    .font(.system(size: 17, weight: .bold))

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                miniStat(value: summary.checkIns, label: "Check-ins")
                miniStat(value: summary.places, label: "Places")
                miniStat(value: summary.alerts, label: "Alerts")
            }

            if !summary.placeNames.isEmpty {
                HStack(spacing: 8) {
                    ForEach(summary.placeNames, id: \.self) { place in
                        Text(place)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(uiColor: .tertiarySystemFill).opacity(0.6))
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5)
        }
    }

    private func miniStat(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 19, weight: .bold))
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(uiColor: .tertiarySystemFill).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
