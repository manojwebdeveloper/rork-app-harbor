import SwiftUI

/// Weekly digest preferences. Delivery day/time are stored for a future
/// per-user delivery scheduler — `generateWeeklyDigests` currently runs on a
/// single fixed weekly schedule for every circle (see the Cloud Function's
/// doc comment), so changing this doesn't yet change exactly when the push
/// arrives, only whether it's sent at all.
struct WeeklyDigestSettingsView: View {
    private static let deliveryOptions: [(label: String, dayOfWeek: Int, hourUTC: Int)] = [
        ("Sundays, 9:00 AM", 0, 9),
        ("Sundays, 6:00 PM", 0, 18),
        ("Mondays, 8:00 AM", 1, 8),
        ("Fridays, 6:00 PM", 5, 18)
    ]

    @EnvironmentObject private var activityService: ActivityService

    @State private var isDigestEnabled = true
    @State private var deliveryIndex = 0
    @State private var isShowingPreview = false
    @State private var isSaving = false
    @State private var errorMessage: String?

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
                    .onChange(of: isDigestEnabled) { _, _ in save() }

                    Divider().padding(.leading, 16)

                    Menu {
                        ForEach(Array(Self.deliveryOptions.enumerated()), id: \.offset) { index, option in
                            Button(option.label) {
                                deliveryIndex = index
                                save()
                            }
                        }
                    } label: {
                        HStack {
                            Text("Arrives")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.primary)

                            Spacer()

                            Text(Self.deliveryOptions[deliveryIndex].label)
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
                .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous)
                        .stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
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
                    .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
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
            DigestNotificationPreviewView(delivery: Self.deliveryOptions[deliveryIndex].label) {
                isShowingPreview = false
            }
        }
    }

    private func save() {
        let option = Self.deliveryOptions[deliveryIndex]
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await activityService.updateDigestPreferences(
                    enabled: isDigestEnabled,
                    dayOfWeek: option.dayOfWeek,
                    hourUTC: option.hourUTC
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
