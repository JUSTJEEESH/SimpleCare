import SwiftUI

struct CircleOfCareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 20)

                    if showContent {
                        // Hero illustration
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(SimpleCareColors.calmBlue)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))

                        VStack(spacing: 12) {
                            Text("Circle of Care")
                                .font(.title.weight(.semibold))
                                .foregroundStyle(SimpleCareColors.charcoal)

                            Text("Share your care with someone you trust — without giving up your privacy.")
                                .font(.body)
                                .foregroundStyle(SimpleCareColors.charcoalLight)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                        }
                        .transition(.opacity)

                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            featureRow(
                                icon: "eye.fill",
                                title: "Read-Only",
                                description: "Family sees your medications and appointments — nothing more."
                            )

                            featureRow(
                                icon: "bell.fill",
                                title: "Gentle Check-Ins",
                                description: "If an important medication is missed, your family gets a quiet nudge."
                            )

                            featureRow(
                                icon: "lock.shield.fill",
                                title: "You're in Control",
                                description: "You choose what to share. You can stop sharing anytime."
                            )

                            featureRow(
                                icon: "icloud.fill",
                                title: "Secure Sync",
                                description: "Shared through iCloud. No accounts. No third-party servers."
                            )
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity)

                        // Pricing
                        VStack(spacing: 12) {
                            Text("Premium Feature")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(SimpleCareColors.calmBlue)

                            Text("$9.99/month or $49.99 one-time")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(SimpleCareColors.charcoal)

                            Text("Designed to be paid for by family —\nnot the person using Simple Care.")
                                .font(.subheadline)
                                .foregroundStyle(SimpleCareColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .padding(.top, 8)
                        .transition(.opacity)

                        // CTA
                        Button {
                            // In production: trigger StoreKit purchase
                            CalmHaptics.gentle()
                        } label: {
                            Text("Start Free Trial")
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 60)
                        }
                        .buttonStyle(PrimaryButtonStyle(backgroundColor: SimpleCareColors.calmBlue))
                        .padding(.horizontal, 32)
                        .transition(.opacity)

                        Text("7-day free trial. Cancel anytime.")
                            .font(.caption)
                            .foregroundStyle(SimpleCareColors.secondaryText)

                        Spacer(minLength: 32)
                    }
                }
            }
            .background(SimpleCareColors.warmBackground)
            .navigationTitle("Circle of Care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(SimpleCareColors.calmBlue)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    showContent = true
                }
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(SimpleCareColors.calmBlue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SimpleCareColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    CircleOfCareView()
}
