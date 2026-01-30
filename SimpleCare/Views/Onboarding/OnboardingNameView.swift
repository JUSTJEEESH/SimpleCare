import SwiftUI

struct OnboardingNameView: View {
    @Binding var name: String
    let onContinue: () -> Void

    @FocusState private var isFieldFocused: Bool
    @State private var showContent = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if showContent {
                VStack(spacing: 16) {
                    Text("What should we call you?")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .multilineTextAlignment(.center)

                    TextField("Your name", text: $name)
                        .font(.title2)
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .multilineTextAlignment(.center)
                        .textContentType(.givenName)
                        .focused($isFieldFocused)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SimpleCareColors.fieldBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(SimpleCareColors.sage.opacity(0.4), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 32)
                        .submitLabel(.continue)
                        .onSubmit {
                            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                CalmHaptics.gentle()
                                onContinue()
                            }
                        }

                    Text("You can change this anytime.")
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                }
                .transition(.opacity)
            }

            Spacer()

            if showButton && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                showContent = true
            }
            // Auto-focus after content appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isFieldFocused = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                showButton = true
            }
        }
        .animation(.easeInOut(duration: 0.3), value: name)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    OnboardingNameView(name: .constant("Mary")) { }
}
