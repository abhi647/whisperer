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
    static let canvas = LinearGradient(
        colors: [Color(nsColor: .windowBackgroundColor), accent.opacity(0.035)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum CardProminence { case standard, hero }

struct WhispererCard: ViewModifier {
    let prominence: CardProminence

    func body(content: Content) -> some View {
        content
            .padding(prominence == .hero ? 22 : 18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: prominence == .hero ? 22 : 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: prominence == .hero ? 22 : 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.075), lineWidth: 1)
            }
            .shadow(color: .black.opacity(prominence == .hero ? 0.11 : 0.055), radius: prominence == .hero ? 20 : 10, y: prominence == .hero ? 8 : 4)
    }
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

    func whispererCard(prominence: CardProminence = .standard) -> some View {
        modifier(WhispererCard(prominence: prominence))
    }
}

struct SectionHeading: View {
    let title: String
    let icon: String

    init(_ title: String, icon: String) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

struct LiveDot: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(isActive ? WhispererTheme.accent : Color.secondary.opacity(0.45))
            .frame(width: 9, height: 9)
            .shadow(color: isActive ? WhispererTheme.accent.opacity(0.5) : .clear, radius: 5)
            .accessibilityHidden(true)
    }
}

struct ReadinessRow: View {
    let title: String
    let ready: Bool
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: ready ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(ready ? WhispererTheme.accent : .secondary)
            Text(title).font(.callout)
            Spacer()
            if let actionTitle {
                Button(actionTitle, action: action).buttonStyle(.link)
            } else {
                Text(ready ? "Ready" : "Needs attention").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

enum NoticeTone { case warning, privacy }

struct NoticeBanner: View {
    let message: String
    let tone: NoticeTone
    var dismiss: (() -> Void)?

    init(message: String, tone: NoticeTone, dismiss: (() -> Void)? = nil) {
        self.message = message
        self.tone = tone
        self.dismiss = dismiss
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: tone == .privacy ? "hand.raised.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(tone == .privacy ? WhispererTheme.accent : WhispererTheme.warning)
            Text(message).font(.callout).fixedSize(horizontal: false, vertical: true)
            Spacer()
            if let dismiss {
                Button(action: dismiss) { Image(systemName: "xmark") }
                    .buttonStyle(.plain).foregroundStyle(.secondary)
                    .accessibilityLabel("Dismiss")
            }
        }
        .padding(14)
        .background((tone == .privacy ? WhispererTheme.accent : WhispererTheme.warning).opacity(0.09), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder((tone == .privacy ? WhispererTheme.accent : WhispererTheme.warning).opacity(0.22))
        }
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
