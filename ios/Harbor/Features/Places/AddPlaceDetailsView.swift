import SwiftUI

/// Placeholder — step 3 of 5: name and category. Alerts move to the next step.
struct AddPlaceDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: Place.Category = .custom
    @State private var isShowingAlertsStep = false

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
                Button("Next") { isShowingAlertsStep = true }
                    .fontWeight(.semibold)
                    .disabled(trimmedName.isEmpty)
            }
        }
        .navigationDestination(isPresented: $isShowingAlertsStep) {
            PlaceAlertsStepView(
                placeName: trimmedName.isEmpty ? "this place" : trimmedName,
                placeAddress: "24 Willow Road"
            ) {
                dismiss()
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
