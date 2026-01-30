import SwiftUI

struct OnboardingPermissionsView: View {
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var remindersEnabled = true
    @State private var calendarEnabled = false
    @State private var iCloudEnabled = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            if showContent {
                VStack(spacing: 28) {
                    Text("Simple Care only asks\nfor what it needs.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(SimpleCareColors.charcoal)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    VStack(spacing: 16) {
                        permissionRow(
                            icon: "bell.fill",
                            title: "Reminders",
                            subtitle: "So we can gently remind you",
                            isOn: $remindersEnabled
                        )

                        permissionRow(
                            icon: "calendar",
                            title: "Calendar",
                            subtitle: "So appointments appear where you expect",
                            isOn: $calendarEnabled,
                            optional: true
                        )

                        permissionRow(
                            icon: "icloud.fill",
                            title: "iCloud",
                            subtitle: "So your care is backed up safely",
                            isOn: $iCloudEnabled,
                            optional: true
                        )
                    }
                    .padding(.horizontal, 8)
                }
                .transition(.opacity)
            }

            Spacer()

            Button("Continue") {
                CalmHaptics.gentle()
                // In a real build, request permissions here based on toggle states
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle())
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

    private func permissionRow(
        icon: String,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        optional: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(SimpleCareColors.calmBlue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(SimpleCareColors.charcoal)
                    if optional {
                        Text("Optional")
                            .font(.caption)
                            .foregroundStyle(SimpleCareColors.secondaryText)
                    }
                }
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .tint(SimpleCareColors.sage)
                .labelsHidden()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle). \(optional ? "Optional." : "") \(isOn.wrappedValue ? "Enabled" : "Disabled")")
    }
}

#Preview {
    OnboardingPermissionsView { }
}
