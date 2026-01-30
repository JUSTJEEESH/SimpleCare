import SwiftUI

struct OnboardingFlowView: View {
    @State private var currentStep = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @State private var enteredName = ""
    @State private var showSharingChoice = false

    var body: some View {
        ZStack {
            SimpleCareColors.warmBackground
                .ignoresSafeArea()

            switch currentStep {
            case 0:
                OnboardingWelcomeView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStep = 1
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case 1:
                OnboardingNameView(name: $enteredName) {
                    userName = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStep = 2
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case 2:
                OnboardingReassuranceView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStep = 3
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case 3:
                OnboardingSharingView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStep = 4
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case 4:
                OnboardingPermissionsView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentStep = 5
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            case 5:
                OnboardingFirstWinView {
                    hasCompletedOnboarding = true
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
}

#Preview {
    OnboardingFlowView()
}
