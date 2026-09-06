import SwiftUI

/// Weekly digest summary. Layout only — every number is static placeholder data.
struct WeeklyDigestView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("\(HarborSample.digestRange) · \(HarborSample.digestCircleName)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    statTile(value: "\(HarborSample.digestCheckIns)", label: "check-ins sent")
                    statTile(value: "\(HarborSample.digestPlaces)", label: "places visited")
                    statTile(value: "\(HarborSample.digestAlerts)", label: "alert · low battery")
                }
                .padding(.top, 14)

                Text("BY MEMBER")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 26)
                    .padding(.bottom, 12)

                VStack(spacing: 14) {
                    ForEach(HarborSample.digestMembers) { member in
                        memberCard(member)
                    }
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
        .clipShape(RoundedRectangle(cornerRadius: HarborRadius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborRadius.field, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5)
        }
    }

    private func memberCard(_ member: SampleMemberDigest) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(member.tint.color.opacity(0.16))
                    .frame(width: 40, height: 40)
                    .overlay { Circle().stroke(member.tint.color, lineWidth: 2) }
                    .overlay {
                        Text(member.initials)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(member.tint.color)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.system(size: 17, weight: .bold))
                    Text(member.summary)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                miniStat(value: member.checkIns, label: "Check-ins")
                miniStat(value: member.places, label: "Places")
                miniStat(value: member.alerts, label: "Alerts")
            }

            if !member.placeNames.isEmpty {
                HStack(spacing: 8) {
                    ForEach(member.placeNames, id: \.self) { place in
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
        .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous)
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
