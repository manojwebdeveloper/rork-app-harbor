import SwiftUI

/// Placeholder — layout only. StoreKit wiring is not part of this pass.
struct SubscriptionView: View {
    enum Plan: String, CaseIterable, Identifiable {
        case monthly = "Monthly family plan"
        case annual = "Annual family plan"

        var id: String { rawValue }

        var price: String {
            switch self {
            case .monthly: "$7.99"
            case .annual: "$59.99"
            }
        }

        var detail: String {
            switch self {
            case .monthly: "Billed monthly · cancel anytime"
            case .annual: "$5.00 / month · 7-day free trial"
            }
        }
    }

    @State private var selectedPlan: Plan?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("One family plan covers everyone in your circles.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 0) {
                    comparisonRow("Circles", free: "1", premium: "Unlimited")
                    Divider()
                    comparisonRow("Members per circle", free: "Up to 4", premium: "Unlimited")
                    Divider()
                    comparisonRow("Saved Places", free: "2", premium: "Unlimited")
                    Divider()
                    comparisonRow("Activity history", free: "2 days", premium: "30 days")
                    Divider()
                    comparisonRow("Temporary travel sharing", free: "—", premium: "Included")
                }
                .padding(.horizontal, 14)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))

                ForEach(Plan.allCases) { plan in
                    Button {
                        selectedPlan = plan
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedPlan == plan ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(
                                    selectedPlan == plan ? Color(.calmTeal) : Color(.slate).opacity(0.5)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(plan.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                Text(plan.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(plan.price)
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
                        .overlay {
                            if selectedPlan == plan {
                                RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                                    .stroke(Color(.calmTeal), lineWidth: 1.5)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                PrimaryButton(
                    title: selectedPlan == nil ? "Choose a plan" : "Start 7-day free trial",
                    isEnabled: selectedPlan != nil
                ) { }

                Text("Purchases are not enabled in this build.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .navigationTitle("HarborPrivateFamilyLocation Premium")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func comparisonRow(_ title: String, free: String, premium: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
            Spacer()
            Text(free)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 66, alignment: .trailing)
            Text(premium)
                .font(.caption.weight(.semibold))
                .frame(width: 76, alignment: .trailing)
        }
        .padding(.vertical, 11)
    }
}
