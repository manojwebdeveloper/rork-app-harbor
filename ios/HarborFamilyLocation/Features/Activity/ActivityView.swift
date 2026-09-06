import SwiftUI

/// Activity tab — layout only. Entries come from static placeholder data.
struct ActivityView: View {
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

                    ActivityTimelineView(entries: HarborFamilyLocationSample.activityToday)

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
                }
            }
            .sheet(isPresented: $isCheckingIn) {
                CheckInSheetView {
                    isCheckingIn = false
                    showingConfirmation = true
                }
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
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
                Text("\(HarborFamilyLocationSample.digestRange) · \(HarborFamilyLocationSample.digestCheckIns) check-ins, \(HarborFamilyLocationSample.digestPlaces) places")
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
        .clipShape(RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborFamilyLocationRadius.card, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.7), lineWidth: 0.5)
        }
    }
}
