import SwiftUI

/// A mock lock screen showing how the weekly digest notification reads,
/// using the circle's real latest digest when one exists.
struct DigestNotificationPreviewView: View {
    let delivery: String
    let onClose: () -> Void

    @EnvironmentObject private var circleService: CircleService
    @EnvironmentObject private var activityService: ActivityService

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.49, green: 0.58, blue: 0.63),
                    Color(red: 0.35, green: 0.46, blue: 0.51)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Text(Self.dateFormatter.string(from: Date()))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 40)

                Text("9:41")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 2)

                notificationCard
                    .padding(.horizontal, 16)
                    .padding(.top, 26)

                Text("Delivered \(delivery) · one notification a week")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.top, 14)
                    .padding(.horizontal, 24)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .harborGlass(in: Circle(), fallback: .ultraThinMaterial)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 30)
                .accessibilityLabel("Close the preview")
            }
        }
    }

    private var notificationCard: some View {
        HStack(alignment: .top, spacing: 11) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(HarborPrivateFamilyLocationGradient.brand)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("HarborPrivateFamilyLocation")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("now")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Text("Your week with \(circleService.selectedCircle?.name ?? "your circle")")
                    .font(.system(size: 15, weight: .bold))

                Text(summaryText)
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter
    }()

    private var summaryText: String {
        guard let digest = activityService.latestDigest else {
            return "Your summary appears here once your circle's first digest is ready. Tap to read it."
        }
        let checkIns = digest.memberSummaries.reduce(0) { $0 + $1.checkIns }
        let places = digest.memberSummaries.reduce(0) { $0 + $1.places }
        let alerts = digest.memberSummaries.reduce(0) { $0 + $1.alerts }
        let alertsText = alerts == 0 ? "no missed alerts" : "\(alerts) alert\(alerts == 1 ? "" : "s")"
        return "\(checkIns) check-ins, \(places) places visited, \(alertsText). Tap to read the summary."
    }
}
