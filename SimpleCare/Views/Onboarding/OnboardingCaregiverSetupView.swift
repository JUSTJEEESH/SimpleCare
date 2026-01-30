import SwiftUI
import SwiftData

struct OnboardingCaregiverSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("caregiverMode") private var caregiverMode = false
    @AppStorage("caregiverName") private var caregiverName = ""
    @AppStorage("userName") private var userName = ""

    let onComplete: () -> Void

    @State private var step = 0
    @State private var seniorName = ""
    @State private var myName = ""
    @State private var myRelationship = "Son"
    @State private var myPhone = ""
    @State private var showContent = false

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i <= step ? SimpleCareColors.calmBlue : SimpleCareColors.upcoming)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            Spacer()

            if showContent {
                switch step {
                case 0:
                    seniorNameStep
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                case 1:
                    caregiverNameStep
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                case 2:
                    caregiverDetailsStep
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                default:
                    EmptyView()
                }
            }

            Spacer()

            if showContent {
                VStack(spacing: 14) {
                    Button(step < 2 ? "Continue" : "Finish Setup") {
                        advanceStep()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .opacity(canContinue ? 1.0 : 0.5)
                    .disabled(!canContinue)

                    if step == 0 {
                        Button("Go back") {
                            onComplete() // exits caregiver flow
                        }
                        .font(.subheadline)
                        .foregroundStyle(SimpleCareColors.secondaryText)
                    }
                }
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showContent = true
            }
        }
        .animation(.easeInOut(duration: 0.4), value: step)
    }

    // MARK: - Step 0: Senior's Name

    private var seniorNameStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(SimpleCareColors.heartRed)

            VStack(spacing: 12) {
                Text("Who are you setting\nthis up for?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Enter their first name — this is how the app will greet them.")
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            TextField("Their name", text: $seniorName)
                .font(.title3)
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
                .padding(.horizontal, 16)
                .submitLabel(.continue)
                .onSubmit {
                    if canContinue { advanceStep() }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isFieldFocused = true
                    }
                }
        }
    }

    // MARK: - Step 1: Caregiver's Name

    private var caregiverNameStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(SimpleCareColors.calmBlue)

            VStack(spacing: 12) {
                Text("And what's your name?")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)

                Text("We'll add you to \(seniorName.isEmpty ? "their" : seniorName + "'s") Circle of Care so they always have your contact info.")
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            TextField("Your name", text: $myName)
                .font(.title3)
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
                .padding(.horizontal, 16)
                .submitLabel(.continue)
                .onSubmit {
                    if canContinue { advanceStep() }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isFieldFocused = true
                    }
                }
        }
    }

    // MARK: - Step 2: Relationship + Phone

    private var caregiverDetailsStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Just a couple more things")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .multilineTextAlignment(.center)

                Text("So \(seniorName.isEmpty ? "they" : seniorName) can reach you easily.")
                    .font(.subheadline)
                    .foregroundStyle(SimpleCareColors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            // Relationship chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Your relationship")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SimpleCareColors.charcoal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(CareCircleMember.relationships, id: \.self) { rel in
                            Button {
                                myRelationship = rel
                                CalmHaptics.selection()
                            } label: {
                                Text(rel)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(myRelationship == rel ? .white : SimpleCareColors.charcoal)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(myRelationship == rel ? SimpleCareColors.calmBlue : SimpleCareColors.fieldBackground)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                myRelationship == rel ? Color.clear : SimpleCareColors.sage.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                }
            }

            // Phone
            VStack(alignment: .leading, spacing: 8) {
                Text("Your phone number")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SimpleCareColors.charcoal)

                TextField("(555) 123-4567", text: $myPhone)
                    .font(.body)
                    .foregroundStyle(SimpleCareColors.charcoal)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .padding(14)
                    .background(SimpleCareColors.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(SimpleCareColors.sage.opacity(0.3), lineWidth: 1)
                    )

                Text("Optional — but helpful for quick contact")
                    .font(.caption)
                    .foregroundStyle(SimpleCareColors.secondaryText)
            }
        }
    }

    // MARK: - Logic

    private var canContinue: Bool {
        switch step {
        case 0: return !seniorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return !myName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return true // phone is optional
        default: return false
        }
    }

    private func advanceStep() {
        guard canContinue else { return }
        CalmHaptics.gentle()

        if step < 2 {
            isFieldFocused = false
            withAnimation {
                step += 1
            }
        } else {
            finishSetup()
        }
    }

    private func finishSetup() {
        // Set the senior's name as the app user
        userName = seniorName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Mark as caregiver setup
        caregiverMode = true
        caregiverName = myName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Create a care circle member for the caregiver
        let member = CareCircleMember(
            name: myName.trimmingCharacters(in: .whitespacesAndNewlines),
            relationship: myRelationship,
            phoneNumber: myPhone.trimmingCharacters(in: .whitespacesAndNewlines),
            isEmergencyContact: true,
            notifyOnMissedDose: true
        )
        modelContext.insert(member)
        try? modelContext.save()

        onComplete()
    }
}

#Preview {
    OnboardingCaregiverSetupView { }
        .modelContainer(for: CareCircleMember.self, inMemory: true)
}
