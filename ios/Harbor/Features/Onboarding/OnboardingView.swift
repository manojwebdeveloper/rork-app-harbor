import SwiftUI

struct OnboardingView: View {
    struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let message: String
    }

    private let pages = [
        Page(
            symbol: "person.3.sequence.fill",
            title: "Stay close, without checking constantly",
            message: "See the people you care about, only when they choose to share."
        ),
        Page(
            symbol: "mappin.and.ellipse",
            title: "Know when they arrive",
            message: "Receive helpful updates for home, school and the places that matter."
        ),
        Page(
            symbol: "hand.raised.fill",
            title: "You control your location",
            message: "Pause, limit or stop sharing at any time."
        )
    ]

    @State private var pageIndex = 0
    @State private var showingPrivacySheet = false

    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 26) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(HarborGradient.brand)
                                .frame(width: 150, height: 150)
                                .shadow(color: Color(.calmTeal).opacity(0.24), radius: 28, y: 14)
                            Image(systemName: page.symbol)
                                .font(.system(size: 54, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)

                        VStack(spacing: 12) {
                            Text(page.title)
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                            Text(page.message)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 28)

                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                PrimaryButton(title: "Continue") {
                    if pageIndex == pages.count - 1 {
                        onComplete()
                    } else {
                        withAnimation(.snappy) { pageIndex += 1 }
                    }
                }

                Button("Learn about privacy") { showingPrivacySheet = true }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.calmTeal))
                    .frame(height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $showingPrivacySheet) {
            PrivacyIntroSheet()
                .presentationDetents([.medium])
        }
    }
}

private struct PrivacyIntroSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Privacy at Harbor")
                .font(.title2.bold())

            Label(
                "No one appears on a map without installing Harbor and accepting an invitation.",
                systemImage: "checkmark.circle.fill"
            )
            Label(
                "A clear list of every person and session with access to your location.",
                systemImage: "eye.fill"
            )
            Label(
                "Stop or limit sharing in one tap. Sharing always has an off switch.",
                systemImage: "pause.circle.fill"
            )

            Spacer()

            PrimaryButton(title: "Done") { dismiss() }
        }
        .font(.subheadline)
        .padding(24)
    }
}
