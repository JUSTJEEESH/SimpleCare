import SwiftUI

// MARK: - Simple Care Color Palette
// Soft sage, calm blue, warm charcoal — never hospital-white, never alarming-red.

enum SimpleCareColors {
    // Primary palette — these accent colors work in both modes
    static let sage = Color(red: 0.56, green: 0.68, blue: 0.58)
    static let sageLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.35, blue: 0.27, alpha: 1)
            : UIColor(red: 0.85, green: 0.91, blue: 0.86, alpha: 1)
    })
    static let sageDark = Color(red: 0.38, green: 0.50, blue: 0.40)

    static let calmBlue = Color(red: 0.45, green: 0.62, blue: 0.78)
    static let calmBlueLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.28, blue: 0.40, alpha: 1)
            : UIColor(red: 0.82, green: 0.89, blue: 0.96, alpha: 1)
    })
    static let calmBlueDark = Color(red: 0.28, green: 0.45, blue: 0.62)

    // Text colors — adapt to light/dark
    static let charcoal = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1)
            : UIColor(red: 0.25, green: 0.27, blue: 0.29, alpha: 1)
    })
    static let charcoalLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.75, green: 0.75, blue: 0.77, alpha: 1)
            : UIColor(red: 0.42, green: 0.44, blue: 0.46, alpha: 1)
    })

    // Semantic colors — adapt to light/dark
    static let warmBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1)
    })
    static let cardBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1)
            : UIColor.white
    })
    static let secondaryText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.62, blue: 0.64, alpha: 1)
            : UIColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1)
    })

    // Status colors — gentle, not alarming
    static let taken = Color(red: 0.45, green: 0.72, blue: 0.52)
    static let skipped = Color(red: 0.88, green: 0.76, blue: 0.38)
    static let upcoming = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.45, blue: 0.47, alpha: 1)
            : UIColor(red: 0.70, green: 0.70, blue: 0.70, alpha: 1)
    })

    // Accent for important actions
    static let primaryAction = calmBlue
    static let destructive = Color(red: 0.82, green: 0.42, blue: 0.42)

    // Input field background — distinct from card background
    static let fieldBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.22, blue: 0.24, alpha: 1)
            : UIColor.white
    })
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = SimpleCareColors.primaryAction

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.medium))
            .foregroundStyle(SimpleCareColors.charcoal)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background(SimpleCareColors.sageLight)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GentleCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(SimpleCareColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func gentleCard() -> some View {
        modifier(GentleCardStyle())
    }
}

// MARK: - Haptics

enum CalmHaptics {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func gentle() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            generator.impactOccurred()
        }
    }

    static func missed() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Time of Day Helper

enum TimeOfDay {
    case morning
    case midday
    case afternoon
    case evening
    case night

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<14: return .midday
        case 14..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }

    var greeting: String {
        switch self {
        case .morning: return "Good morning"
        case .midday: return "Good afternoon"
        case .afternoon: return "Good afternoon"
        case .evening: return "Good evening"
        case .night: return "Good evening"
        }
    }
}
