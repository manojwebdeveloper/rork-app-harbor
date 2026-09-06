import SwiftUI

/// Phase 2 circle creation flow: kind → duration (travel only) → name → ready.
/// Layout and navigation only — no circle is created and nothing is written anywhere.
struct NewCircleFlowView: View {
    private enum Step: Hashable {
        case duration
        case name
        case ready
    }

    enum CircleKind: Hashable {
        case everyday
        case travel

        var isTravel: Bool { self == .travel }
    }

    let onFinished: () -> Void

    @State private var path: [Step] = []
    @State private var kind: CircleKind = .everyday
    @State private var duration: TripDuration = .oneWeek
    @State private var name = ""

    var body: some View {
        NavigationStack(path: $path) {
            CircleKindStepView { selected in
                kind = selected
                path.append(selected.isTravel ? .duration : .name)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onFinished)
                }
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .duration:
                    TripDurationStepView(selection: $duration) {
                        path.append(.name)
                    }

                case .name:
                    NameCircleStepView(
                        kind: kind,
                        duration: duration,
                        name: $name,
                        onChangeDuration: { path.removeLast() },
                        onCreate: { path.append(.ready) }
                    )

                case .ready:
                    CircleReadyStepView(
                        name: name.isEmpty ? "Paris Trip" : name,
                        kind: kind,
                        duration: duration,
                        onDone: onFinished
                    )
                    .navigationBarBackButtonHidden()
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }
}

enum TripDuration: Hashable, CaseIterable, Identifiable {
    case threeDays
    case oneWeek
    case custom

    var id: Self { self }

    var title: String {
        switch self {
        case .threeDays: "3 days"
        case .oneWeek: "1 week"
        case .custom: "Custom end date"
        }
    }

    var detail: String {
        switch self {
        case .threeDays: "Ends Tuesday, 8:00 PM"
        case .oneWeek: "Ends Saturday 13 Sep, 8:00 PM"
        case .custom: "Pick the day it should end"
        }
    }

    var endsText: String {
        switch self {
        case .threeDays: "Ends Tuesday, 8:00 PM"
        case .oneWeek: "Ends Saturday 13 Sep, 8:00 PM"
        case .custom: "Ends on your chosen date"
        }
    }
}

/// Step 1 — everyday or travel circle.
private struct CircleKindStepView: View {
    let onSelect: (NewCircleFlowView.CircleKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What kind of circle?")
                .font(HarborPrivateFamilyLocationTypography.display)
                .padding(.top, 28)

            Text("Both are private and invitation-only. A travel circle ends by itself, so no one keeps sharing after the trip.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .padding(.top, 12)

            VStack(spacing: 14) {
                option(
                    symbol: "person.2.fill",
                    tint: Color(.calmTeal),
                    title: "Everyday circle",
                    detail: "Family or friends. Stays until you close it."
                ) {
                    onSelect(.everyday)
                }

                option(
                    symbol: "paperplane.fill",
                    tint: Color(.clearSky),
                    title: "Travel circle",
                    detail: "For a trip. Dissolves on its own when the trip ends."
                ) {
                    onSelect(.travel)
                }
            }
            .padding(.top, 28)

            Spacer()

            Text("You can convert a travel circle to permanent later.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .background(Color(uiColor: .systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func option(
        symbol: String,
        tint: Color,
        title: String,
        detail: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.16))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(tint)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.primary)
                    Text(detail)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.card, style: .continuous)
                    .stroke(Color(.mineralBorder).opacity(0.8), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Step 2 — how long the travel circle lasts.
private struct TripDurationStepView: View {
    @Binding var selection: TripDuration
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(.clearSky).opacity(0.16))
                    .frame(width: 26, height: 26)
                    .overlay {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(.clearSky))
                    }

                Text("TRAVEL CIRCLE")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(.clearSky))
            }
            .padding(.top, 8)

            Text("How long is the trip?")
                .font(HarborPrivateFamilyLocationTypography.title)
                .padding(.top, 14)

            Text("Everyone stops sharing automatically when it ends. No one has to remember to switch it off.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .padding(.top, 10)

            VStack(spacing: 12) {
                ForEach(TripDuration.allCases) { duration in
                    Button {
                        withAnimation(.snappy(duration: 0.2)) { selection = duration }
                    } label: {
                        row(for: duration)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 24)

            Spacer()

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text("Sharing stops on \(selection.detail.replacingOccurrences(of: "Ends ", with: "")). You can extend it any time before then.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
            .padding(.bottom, 16)

            PrimaryButton(title: "Continue", action: onContinue)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .background(Color(uiColor: .systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for duration: TripDuration) -> some View {
        let isSelected = duration == selection

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(.calmTeal) : Color(.mineralBorder), lineWidth: 2)
                    .frame(width: 22, height: 22)

                if isSelected {
                    Circle()
                        .fill(Color(.calmTeal))
                        .frame(width: 11, height: 11)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(duration.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primary)
                Text(duration.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous)
                .stroke(
                    isSelected ? Color(.calmTeal) : Color(.mineralBorder).opacity(0.8),
                    lineWidth: isSelected ? 2 : 0.5
                )
        }
    }
}

/// Step 3 — name the circle.
private struct NameCircleStepView: View {
    let kind: NewCircleFlowView.CircleKind
    let duration: TripDuration
    @Binding var name: String
    let onChangeDuration: () -> Void
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(kind.isTravel ? "Name this trip" : "Name this circle")
                .font(HarborPrivateFamilyLocationTypography.title)
                .padding(.top, 12)

            Text("Only the people you invite can see or join it.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            TextField(kind.isTravel ? "e.g. Paris Trip" : "e.g. The Harris Family", text: $name)
                .font(.system(size: 16))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
                .padding(.top, 22)

            if kind.isTravel {
                HStack(spacing: 13) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.clearSky).opacity(0.16))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(.clearSky))
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Travel circle")
                            .font(.system(size: 15, weight: .bold))
                        Text(duration.endsText)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Button("Change", action: onChangeDuration)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(.calmTeal))
                }
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: HarborPrivateFamilyLocationRadius.field, style: .continuous)
                        .stroke(Color(.mineralBorder).opacity(0.8), lineWidth: 0.5)
                }
                .padding(.top, 12)
            }

            Spacer()

            PrimaryButton(
                title: kind.isTravel ? "Create travel circle" : "Create circle",
                isEnabled: isValid,
                action: onCreate
            )
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .background(Color(uiColor: .systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
}

/// Step 4 — the circle is ready to share.
private struct CircleReadyStepView: View {
    let name: String
    let kind: NewCircleFlowView.CircleKind
    let duration: TripDuration
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 90)

            Circle()
                .fill(HarborPrivateFamilyLocationGradient.brand)
                .frame(width: 62, height: 62)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

            Text("\(name) is ready")
                .font(HarborPrivateFamilyLocationTypography.title)
                .multilineTextAlignment(.center)
                .padding(.top, 22)

            if kind.isTravel {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(duration.endsText)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color(.clearSky))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color(.clearSky).opacity(0.14))
                .clipShape(Capsule())
                .padding(.top, 12)
            }

            Text(kind.isTravel
                 ? "Invite your travel companions. Everyone chooses to share, and sharing stops by itself when the trip ends."
                 : "Invite the people you want in this circle. Everyone chooses to share, and can stop any time.")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .padding(.horizontal, 12)

            Spacer()

            PrimaryButton(title: "Share invitation link") { }

            Button("Done", action: onDone)
                .font(.headline)
                .foregroundStyle(Color(.calmTeal))
                .padding(.top, 14)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
