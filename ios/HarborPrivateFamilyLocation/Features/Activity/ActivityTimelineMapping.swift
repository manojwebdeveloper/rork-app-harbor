import Foundation

/// Shared by `ActivityView` and `CircleActivityPreviewView` so both build the
/// same `SampleActivityEntry` timeline from real check-ins/activity data.
enum ActivityTimelineMapping {
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let tintPalette: [SampleTint] = [.sky, .teal, .coral, .amber]

    static func entries(
        checkIns: [CheckIn],
        serverActivity: [ServerActivityEntry],
        members: [FirebaseCircleMember]
    ) -> [SampleActivityEntry] {
        func tint(for memberID: String?) -> SampleTint {
            guard let memberID, let index = members.firstIndex(where: { $0.id == memberID }) else { return .teal }
            return tintPalette[index % tintPalette.count]
        }
        func name(for memberID: String?) -> String {
            guard let memberID else { return "Someone" }
            return members.first { $0.id == memberID }?.displayName ?? "Someone"
        }

        let checkInEntries = checkIns.map { checkIn -> (Date, SampleActivityEntry) in
            let detail = checkIn.message == .custom ? (checkIn.customText ?? "") : "Check-in"
            return (checkIn.sentAt, SampleActivityEntry(
                id: checkIn.id,
                time: timeFormatter.string(from: checkIn.sentAt),
                title: "\(name(for: checkIn.userID)) · \(checkIn.message.rawValue)",
                detail: detail,
                tint: tint(for: checkIn.userID),
                badge: nil
            ))
        }

        let serverEntries = serverActivity.map { entry -> (Date, SampleActivityEntry) in
            (entry.createdAt, SampleActivityEntry(
                id: entry.id,
                time: timeFormatter.string(from: entry.createdAt),
                title: entry.title,
                detail: entry.detail,
                tint: tint(for: entry.memberID),
                badge: entry.kind == "safe" ? "SAFE" : (entry.kind == "smartAlert" ? "ALERT" : nil)
            ))
        }

        return (checkInEntries + serverEntries)
            .sorted { $0.0 < $1.0 }
            .map(\.1)
    }
}
