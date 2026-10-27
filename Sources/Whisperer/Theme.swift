import SwiftUI

enum WhispererTheme {
    static let background = Color(red: 0.094, green: 0.129, blue: 0.141)
    static let panel = Color(red: 0.12, green: 0.165, blue: 0.18)
    static let primary = Color(red: 0.969, green: 0.973, blue: 0.973)
    static let secondary = Color(red: 0.651, green: 0.714, blue: 0.733)
    static let accent = Color(red: 0.569, green: 0.749, blue: 0.663)
    static let warning = Color(red: 0.89, green: 0.737, blue: 0.471)
    static let critical = Color(red: 0.882, green: 0.576, blue: 0.553)
    static let stroke = Color(red: 0.251, green: 0.314, blue: 0.341)
}

struct PremiumGlassSurface: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

extension View {
    func premiumGlass(cornerRadius: CGFloat = 18) -> some View {
        modifier(PremiumGlassSurface(cornerRadius: cornerRadius))
    }
}

struct StatusPill: View {
    let status: SessionStatus

    private var color: Color {
        switch status {
        case .ready, .listening: WhispererTheme.accent
        case .privacyWarning: WhispererTheme.warning
        case .unavailable: WhispererTheme.critical
        default: WhispererTheme.secondary
        }
    }

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(status.rawValue.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
        }
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session status: \(status.rawValue)")
    }
}

struct LevelMeter: View {
    let channel: AudioChannel

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(channel.name).font(.caption)
                Spacer()
                Text(channel.isAvailable ? "CONNECTED" : "UNAVAILABLE")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(channel.isAvailable ? WhispererTheme.accent : WhispererTheme.critical)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(WhispererTheme.stroke.opacity(0.7))
                    Capsule().fill(WhispererTheme.accent)
                        .frame(width: max(3, proxy.size.width * channel.level))
                }
            }
            .frame(height: 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(channel.name), \(Int(channel.level * 100)) percent")
    }
}
