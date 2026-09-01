import SwiftUI

struct CircleSelectorView: View {
    @EnvironmentObject private var circleService: CircleService

    let selected: FirebaseCircleSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(selected.name)
                    .font(.title2.bold())
                Text(selected.kind.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                ForEach(circleService.circles) { circle in
                    Button {
                        circleService.selectCircle(circle.id)
                    } label: {
                        if circle.id == selected.id {
                            Label(circle.name, systemImage: "checkmark")
                        } else {
                            Text(circle.name)
                        }
                    }
                }
            } label: {
                Label("Switch", systemImage: "chevron.up.chevron.down")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.top, 8)
    }
}
