import SwiftUI

struct OnboardingFirstWinView: View {
    let onComplete: () -> Void

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            if showContent {
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SimpleCareColors.sage)

                    Text(timeAwareGreeting)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .multilineTextAlignment(.center)

                    Text("Let's add your first medication")
                        .font(.title3)
                        .foregroundStyle(SimpleCareColors.charcoalLight)
                        .multilineTextAlignment(.center)

                    Text("This only takes a moment.")
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }
                .transition(.opacity)
            }

            Spacer()

            VStack(spacing: 14) {
                Button("Add Medication") {
                    CalmHaptics.gentle()
                    onComplete()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("I'll do this later") {
                    CalmHaptics.selection()
                    onComplete()
                }
                .font(.body)
                .foregroundStyle(SimpleCareColors.secondaryText)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var timeAwareGreeting: String {
        let greeting = TimeOfDay.current.greeting
        return "\(greeting)!"
    }
}

#Preview {
    OnboardingFirstWinView { }
}
