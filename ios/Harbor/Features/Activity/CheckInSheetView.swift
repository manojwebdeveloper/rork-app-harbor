import SwiftUI

/// Placeholder — layout only. Sending check-ins arrives with the backend pass.
struct CheckInSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var message: CheckIn.Message = .safe
    @State private var customText = ""
    @State private var sharingWindow: CheckIn.SharingWindow? = .oneHour

    let onSend: () -> Void

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
                .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))

                if message == .custom {
                    TextField("Add a short message", text: $customText, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(12)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: HarborRadius.field, style: .continuous))
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

                PrimaryButton(title: "Send check-in", action: onSend)

                Button("Cancel") { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.calmTeal))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(20)
        }
    }
}
