import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void
    var onCaregiverSetup: (() -> Void)?

    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var gradientPhase: CGFloat = 0

    var body: some View {
        ZStack {
            // Soft breathing gradient
            LinearGradient(
                colors: [
                    SimpleCareColors.sageLight.opacity(0.6),
                    SimpleCareColors.calmBlueLight.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(
                    x: 0.5 + 0.3 * sin(gradientPhase),
                    y: 1.0 + 0.2 * cos(gradientPhase)
                )
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if showTitle {
                    Text("Welcome to Simple Care")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                if showSubtitle {
                    Text("This app is here to make things easier.")
                        .font(.title3)
                        .foregroundStyle(SimpleCareColors.charcoalLight)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                Spacer()

                if showButton {
                    VStack(spacing: 16) {
                        Button("Get Started") {
                            CalmHaptics.gentle()
                            onContinue()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        if let caregiverAction = onCaregiverSetup {
                            Button {
                                CalmHaptics.selection()
                                caregiverAction()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.2.fill")
                                        .font(.subheadline)
                                    Text("Setting this up for someone?")
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(SimpleCareColors.calmBlue)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 32)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Breathing gradient animation
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                gradientPhase = .pi * 2
            }

            // Sequenced reveal
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(1.3)) {
                showSubtitle = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(2.3)) {
                showButton = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Welcome to Simple Care. This app is here to make things easier.")
    }
}

#Preview {
    OnboardingWelcomeView { }
}
