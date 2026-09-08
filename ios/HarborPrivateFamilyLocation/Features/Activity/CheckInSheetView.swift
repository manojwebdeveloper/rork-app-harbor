import SwiftUI

struct CheckInSheetView: View {
    let circleID: String
    let onSend: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var activityService: ActivityService

    @State private var message: CheckIn.Message = .safe
    @State private var customText = ""
    @State private var sharingWindow: CheckIn.SharingWindow? = .oneHour
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Check in")
                    .font(.title2.bold())

                VStack(spacing: 0) {
                    ForEach(Array(CheckIn.Message.allCases.enumerated()), id: \.element.id) { index, option in
                        Button {
                            message = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                Spacer()
                                Image(systemName: message == option ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(
                                        message == option ? Color(.calmTeal) : Color(.slate).opacity(0.5)
                                    )
                            }
                            .font(.subheadline)
                            .padding(.vertical, 13)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < CheckIn.Message.allCases.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))

                if message == .custom {
                    TextField("Add a short message", text: $customText, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
                }

                Text("ALSO SHARE MY LOCATION FOR")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8)], spacing: 8) {
                    ForEach(CheckIn.SharingWindow.allCases) { window in
                        Button {
                            sharingWindow = sharingWindow == window ? nil : window
                        } label: {
                            Text(window.rawValue)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .foregroundStyle(sharingWindow == window ? .white : Color.primary)
                                .background(
                                    sharingWindow == window
                                        ? Color(.calmTeal)
                                        : Color(uiColor: .secondarySystemBackground)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                }

                PrimaryButton(title: isSending ? "Sending…" : "Send check-in", action: send)
                    .disabled(isSending)

                Button("Cancel") { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.calmTeal))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(20)
        }
    }

    private func send() {
        isSending = true
        errorMessage = nil
        Task {
            do {
                try await activityService.sendCheckIn(
                    circleID: circleID,
                    message: message,
                    customText: customText,
                    sharingWindow: sharingWindow
                )
                isSending = false
                onSend()
            } catch {
                isSending = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
