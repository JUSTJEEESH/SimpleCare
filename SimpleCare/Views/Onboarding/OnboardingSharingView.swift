import SwiftUI

struct OnboardingSharingView: View {
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showButtons = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if showContent {
                VStack(spacing: 16) {
                    Text("Would you like to share\nyour care with someone\nyou trust?")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .transition(.opacity)
            }

            Spacer()

            if showButtons {
                VStack(spacing: 14) {
                    Button("Not right now") {
                        CalmHaptics.gentle()
                        onContinue()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Yes, later") {
                        CalmHaptics.gentle()
                        onContinue()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Text("You are always in control.")
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showButtons = true
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    OnboardingSharingView { }
}
