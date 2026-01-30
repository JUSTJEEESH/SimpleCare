import SwiftUI

struct OnboardingReassuranceView: View {
    let onContinue: () -> Void

    @State private var showTitle = false
    @State private var showCheck1 = false
    @State private var showCheck2 = false
    @State private var showCheck3 = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if showTitle {
                Text("Simple Care helps you remember what matters — quietly.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .transition(.opacity)
            }

            VStack(alignment: .leading, spacing: 20) {
                if showCheck1 {
                    checkmarkRow("Medications")
                        .transition(.opacity.combined(with: .offset(y: 8)))
                }
                if showCheck2 {
                    checkmarkRow("Appointments")
                        .transition(.opacity.combined(with: .offset(y: 8)))
                }
                if showCheck3 {
                    checkmarkRow("Peace of mind")
                        .transition(.opacity.combined(with: .offset(y: 8)))
                }
            }
            .padding(.horizontal, 48)

            Spacer()

            if showButton {
                Button("Continue") {
                    CalmHaptics.gentle()
                    onContinue()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                showCheck1 = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.6)) {
                showCheck2 = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(2.2)) {
                showCheck3 = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(2.8)) {
                showButton = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Simple Care helps you remember what matters quietly. Medications. Appointments. Peace of mind.")
    }

    private func checkmarkRow(_ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(SimpleCareColors.sage)
            Text(text)
                .font(.title3)
                .foregroundStyle(SimpleCareColors.charcoal)
        }
    }
}

#Preview {
    OnboardingReassuranceView { }
}
