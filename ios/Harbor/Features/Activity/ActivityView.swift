import SwiftUI

/// Placeholder — layout only. Real events arrive with the location and notification services.
struct ActivityView: View {
    @State private var selectedFilter: ActivityFilter = .all
    @State private var isCheckingIn = false
    @State private var showingConfirmation = false

    enum ActivityFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case places = "Places"
        case checkIns = "Check-ins"
        case system = "System"

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ActivityFilter.allCases) { filter in
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                Text(filter.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(
                                        selectedFilter == filter ? .white : Color.primary
                                    )
                                    .background(
                                        selectedFilter == filter
                                            ? Color(.calmTeal)
                                            : Color(uiColor: .secondarySystemBackground)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .contentMargins(.horizontal, 20)

                ContentUnavailableView {
                    Label("No activity yet", systemImage: "clock")
                } description: {
                    Text("Arrivals, departures and check-ins appear here once the location and notification services are connected.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("Activity is visible only to your circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 110)
            }
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
}
