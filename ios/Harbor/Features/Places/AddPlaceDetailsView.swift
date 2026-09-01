import SwiftUI

/// Placeholder — step 4 of 4: name, category and alert preferences.
struct AddPlaceDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: Place.Category = .custom
    @State private var arrivalAlertsEnabled = true
    @State private var departureAlertsEnabled = true

    var body: some View {
        Form {
            Section {
                TextField("e.g. Pool, Grandma's, Office", text: $name)
                    .textInputAutocapitalization(.words)
            }

            Section("Category") {
                Picker("Category", selection: $category) {
                    ForEach(Place.Category.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Alerts") {
                Toggle("Arrival alerts", isOn: $arrivalAlertsEnabled)
                Toggle("Departure alerts", isOn: $departureAlertsEnabled)
            }

            Section {
                Text("Saving places needs the location engine. This screen is layout only for now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Name this Place")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { dismiss() }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
