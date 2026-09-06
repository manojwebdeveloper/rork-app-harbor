import SwiftUI

/// Sentence-style Smart Alert builder. Layout only — no rule is ever evaluated.
struct SmartAlertRuleBuilderView: View {
    private enum Field: String, Identifiable {
        case person
        case event
        case comparator
        case time

        var id: String { rawValue }

        var title: String {
            switch self {
            case .person: "Who is this about?"
            case .event: "What happens?"
            case .comparator: "Before or after?"
            case .time: "At what time?"
            }
        }

        var options: [String] {
            switch self {
            case .person: ["Emily", "Maya", "James", "Anyone", "Not everyone"]
            case .event: ["arrives", "leaves", "is still here", "is home"]
            case .comparator: ["after", "before", "by"]
            case .time: ["3:30 PM", "5:00 PM", "6:00 PM", "8:00 PM", "10:00 PM", "11:00 PM"]
            }
        }
    }

    private static let frequencies = ["Every time", "Once a day", "Weekly summary"]
    private static let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

    let placeName: String
    let onAdd: () -> Void

    @State private var person = "Emily"
    @State private var event = "arrives"
    @State private var comparator = "after"
    @State private var time = "6:00 PM"
    @State private var frequency = "Every time"
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5]
    @State private var editingField: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Tap any underlined word to change it.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    sentenceCard
                        .padding(.top, 16)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text("Only fires when \(person) \(event) at \(placeName) \(comparator) \(time). Nothing changes for \(person).")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 14)

                    sectionHeader("HOW OFTEN")
                        .padding(.top, 24)

                    frequencyPicker
                        .padding(.top, 10)

                    sectionHeader("ON THESE DAYS")
                        .padding(.top, 24)

                    dayPicker
                        .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            PrimaryButton(title: "Add Smart Alert", action: onAdd)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("New Smart Alert")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingField) { field in
            SmartAlertOptionPicker(
                title: field.title,
                options: field.options,
                selection: value(for: field)
            ) { newValue in
                apply(newValue, to: field)
                editingField = nil
            } onCancel: {
                editingField = nil
            }
            .presentationDetents([.medium])
        }
    }

    private var sentenceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Notify me if")
                    .font(.system(size: 19))
                token(person, field: .person)
                token(event, field: .event)
            }

            HStack(spacing: 8) {
                token(comparator, field: .comparator)
                token(time, field: .time)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous)
                .stroke(Color(.mineralBorder).opacity(0.8), lineWidth: 0.5)
        }
    }

    private func token(_ value: String, field: Field) -> some View {
        Button {
            editingField = field
        } label: {
            HStack(spacing: 5) {
                Text(value)
                    .font(.system(size: 19, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color(.calmTeal))
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color(.seaGlass))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.calmTeal))
                    .frame(height: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.secondary)
    }

    private var frequencyPicker: some View {
        HStack(spacing: 0) {
            ForEach(Self.frequencies, id: \.self) { option in
                Button {
                    withAnimation(.snappy(duration: 0.2)) { frequency = option }
                } label: {
                    Text(option)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(frequency == option ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            frequency == option
                                ? Color(uiColor: .systemBackground)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            if frequency == option {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color(.mineralBorder), lineWidth: 0.5)
                            }
                        }
                        .shadow(
                            color: .black.opacity(frequency == option ? 0.08 : 0),
                            radius: 6,
                            y: 2
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(uiColor: .secondarySystemFill).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var dayPicker: some View {
        HStack(spacing: 8) {
            ForEach(Array(Self.dayLabels.enumerated()), id: \.offset) { index, label in
                Button {
                    withAnimation(.snappy(duration: 0.15)) { toggleDay(index) }
                } label: {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selectedDays.contains(index) ? .white : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedDays.contains(index)
                                ? Color(.calmTeal)
                                : Color(uiColor: .systemBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    selectedDays.contains(index)
                                        ? Color.clear
                                        : Color(.mineralBorder),
                                    lineWidth: 1
                                )
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleDay(_ index: Int) {
        if selectedDays.contains(index) {
            selectedDays.remove(index)
        } else {
            selectedDays.insert(index)
        }
    }

    private func value(for field: Field) -> String {
        switch field {
        case .person: person
        case .event: event
        case .comparator: comparator
        case .time: time
        }
    }

    private func apply(_ newValue: String, to field: Field) {
        switch field {
        case .person: person = newValue
        case .event: event = newValue
        case .comparator: comparator = newValue
        case .time: time = newValue
        }
    }
}

/// Bottom sheet used to change one word of the rule sentence.
struct SmartAlertOptionPicker: View {
    let title: String
    let options: [String]
    let selection: String
    let onSelect: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.element) { index, option in
                        Button {
                            onSelect(option)
                        } label: {
                            HStack {
                                Text(option)
                                    .font(.system(size: 16, weight: option == selection ? .bold : .regular))
                                    .foregroundStyle(Color.primary)

                                Spacer()

                                if option == selection {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Color(.calmTeal))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < options.count - 1 {
                            Divider().padding(.leading, 18)
                        }
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: HarborRadius.field, style: .continuous))
                .padding(.horizontal, 20)
            }

            Button(action: onCancel) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundStyle(Color(.calmTeal))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(uiColor: .systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: HarborRadius.card, style: .continuous)
                            .stroke(Color(.mineralBorder), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
