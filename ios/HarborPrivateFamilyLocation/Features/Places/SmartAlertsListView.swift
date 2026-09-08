import SwiftUI

/// Smart Alerts for one place: empty state, rule list and delete confirmation.
struct SmartAlertsListView: View {
    let circleID: String
    let placeID: String
    let placeName: String
    let placeAddress: String

    @EnvironmentObject private var placesService: PlacesService
    @EnvironmentObject private var circleService: CircleService

    @State private var isBuildingRule = false
    @State private var rulePendingDeletion: SmartAlertRule?
    @State private var errorMessage: String?

    private static let ruleExamples = [
        "Notify me if Emily arrives after 6:00 PM",
        "Notify me if anyone leaves before 8:00 AM",
        "Notify me if not everyone is home by 8:00 PM"
    ]

    private var rules: [SmartAlertRule] {
        placesService.alertRulesByPlaceID[placeID] ?? []
    }

    var body: some View {
        Group {
            if rules.isEmpty {
                emptyState
            } else {
                ruleList
            }
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Smart Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isBuildingRule) {
            SmartAlertRuleBuilderView(
                circleID: circleID,
                placeID: placeID,
                placeName: placeName,
                members: circleService.members
            ) {
                isBuildingRule = false
            }
        }
        .alert(
            "Delete this Smart Alert?",
            isPresented: Binding(
                get: { rulePendingDeletion != nil },
                set: { if !$0 { rulePendingDeletion = nil } }
            ),
            presenting: rulePendingDeletion
        ) { rule in
            Button("Cancel", role: .cancel) { rulePendingDeletion = nil }
            Button("Delete", role: .destructive) { delete(rule) }
        } message: { _ in
            Text("You'll stop getting this notification. Arrival and departure alerts aren't affected.")
        }
        .onAppear {
            placesService.observeAlertRules(circleID: circleID, placeID: placeID)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Circle()
                .fill(Color(uiColor: .secondarySystemFill).opacity(0.5))
                .frame(width: 62, height: 62)
                .overlay {
                    Image(systemName: "clock")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(.secondary)
                }

            Text("No Smart Alerts yet")
                .font(.system(size: 22, weight: .bold))
                .padding(.top, 18)

            Text("Smart Alerts tell you when something happens later than usual — like arriving after dark, or nobody home by bedtime.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 26)

            Text("START FROM AN EXAMPLE")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.top, 28)

            VStack(spacing: 10) {
                ForEach(Self.ruleExamples, id: \.self) { example in
                    Button {
                        isBuildingRule = true
                    } label: {
                        Text(example)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 15)
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(.mineralBorder), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 14)
            .padding(.horizontal, 20)

            Spacer()

            PrimaryButton(title: "+  Write a rule") {
                isBuildingRule = true
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    private var ruleList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(placeName) · \(placeAddress)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(.signalRed))
                }

                ForEach(rules) { rule in
                    ruleCard(rule)
                }

                addRuleCard

                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "shield")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Text("Smart Alerts run against locations your circle already shares. They don't add any new tracking, and the people named never see the rule.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
    }

    private func ruleCard(_ rule: SmartAlertRule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text(rule.sentence)
                    .font(.system(size: 16, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Toggle("", isOn: toggleBinding(for: rule))
                    .labelsHidden()
                    .tint(Color(.safeGreen))
            }

            HStack(spacing: 8) {
                Text(rule.frequency.rawValue)
                Text("·")
                Text(dayText(for: rule))

                Spacer(minLength: 0)

                Button {
                    rulePendingDeletion = rule
                } label: {
                    Text("Delete")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(.signalRed))
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.8), lineWidth: 0.5)
        }
    }

    private var addRuleCard: some View {
        Button {
            isBuildingRule = true
        } label: {
            HStack(spacing: 13) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(.seaGlass))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(.calmTeal))
                    }

                Text("Add another rule")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(.calmTeal))

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                    .strokeBorder(
                        Color(.mineralBorder),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 5])
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func dayText(for rule: SmartAlertRule) -> String {
        if rule.days.count == 7 { return "Every day" }
        if rule.days == [1, 2, 3, 4, 5] { return "Weekdays" }
        return "\(rule.days.count) days"
    }

    private func toggleBinding(for rule: SmartAlertRule) -> Binding<Bool> {
        Binding(
            get: { rule.isOn },
            set: { newValue in
                Task {
                    do {
                        try await placesService.setAlertRule(isOn: newValue, circleID: circleID, placeID: placeID, ruleID: rule.id)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        )
    }

    private func delete(_ rule: SmartAlertRule) {
        rulePendingDeletion = nil
        Task {
            do {
                try await placesService.deleteAlertRule(circleID: circleID, placeID: placeID, ruleID: rule.id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
