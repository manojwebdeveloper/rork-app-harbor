import SwiftUI

/// Weekly digest preferences. Layout only — nothing is scheduled or persisted.
struct WeeklyDigestSettingsView: View {
    private static let deliveryOptions = [
        "Sundays, 9:00 AM",
        "Sundays, 6:00 PM",
        "Mondays, 8:00 AM",
        "Fridays, 6:00 PM"
    ]

    @State private var isDigestEnabled = true
    @State private var delivery = "Sundays, 9:00 AM"
    @State private var isShowingPreview = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 0) {
                    Toggle(isOn: $isDigestEnabled) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Send me a weekly digest")
                                .font(.system(size: 16))
                            Text("One notification a week. No daily nudges.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color(.safeGreen))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    Divider().padding(.leading, 16)

                    Menu {
                        ForEach(Self.deliveryOptions, id: \.self) { option in
                            Button(option) { delivery = option }
                        }
                    } label: {
                        HStack {
                            Text("Arrives")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.primary)

                            Spacer()

                            Text(delivery)
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 15)
                        .contentShape(Rectangle())
                    }
                    .disabled(!isDigestEnabled)
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.field, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.field, style: .continuous)
                        .stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5)
                }

                Text("Everyone in the circle gets the same summary, so nobody is reported on behind their back.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            Button {
                isShowingPreview = true
            } label: {
                Text("Preview the notification")
                    .font(.headline)
                    .foregroundStyle(Color(.calmTeal))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous)
                            .stroke(Color(.mineralBorder), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Weekly digest")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isShowingPreview) {
            DigestNotificationPreviewView(delivery: delivery) {
                isShowingPreview = false
            }
        }
    }
}
