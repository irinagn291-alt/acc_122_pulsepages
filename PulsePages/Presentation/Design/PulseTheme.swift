import SwiftUI

enum PulseTheme {
    static let orchid = Color(red: 0.424, green: 0.235, blue: 0.878)
    static let pink = Color(red: 1.0, green: 0.420, blue: 0.616)
    static let mint = Color(red: 0.0, green: 0.898, blue: 0.765)
    static let canvas = Color(red: 0.102, green: 0.063, blue: 0.157)
    static let surface = Color(red: 0.145, green: 0.090, blue: 0.216)
    static let ink = Color.white.opacity(0.92)
    static let muted = Color.white.opacity(0.55)
    static let border = Color.white.opacity(0.12)
    static let alert = Color(red: 1.0, green: 0.35, blue: 0.45)
}

struct PulseBackdrop: View {
    var body: some View {
        PulseTheme.canvas.ignoresSafeArea()
    }
}

struct PulseOfflineBanner: View {
    var body: some View {
        Label("You're offline — catalog sync paused.", systemImage: "wifi.slash")
            .font(.caption.weight(.semibold))
            .foregroundStyle(PulseTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(PulseTheme.pink.opacity(0.18))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(PulseTheme.border))
    }
}

struct PulseSpinner: View {
    let caption: String
    init(_ caption: String = "Syncing pulse…") { self.caption = caption }
    var body: some View {
        VStack(spacing: 14) {
            ProgressView().tint(PulseTheme.mint)
            Text(caption).font(.subheadline).foregroundStyle(PulseTheme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PulseEmptyState: View {
    let headline: String
    let detail: String
    let glyph: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: glyph).font(.largeTitle).foregroundStyle(PulseTheme.orchid)
            Text(headline).font(.headline).foregroundStyle(PulseTheme.ink)
            Text(detail).font(.footnote).foregroundStyle(PulseTheme.muted).multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PulseFaultCard: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text(message).font(.footnote).foregroundStyle(PulseTheme.alert).multilineTextAlignment(.center)
            Button("Try again", action: retry)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(PulseTheme.orchid.opacity(0.25))
                .foregroundStyle(PulseTheme.mint)
                .clipShape(Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CoverTile: View {
    let token: Int?
    var width: CGFloat = 48
    var height: CGFloat = 72

    var body: some View {
        Group {
            if let url = token.flatMap({ OpenLibraryEndpoints.coverURL(token: $0, size: "S") }) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase { img.resizable().scaledToFill() }
                    else { placeholder }
                }
            } else { placeholder }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(PulseTheme.border))
    }

    private var placeholder: some View {
        ZStack {
            PulseTheme.surface
            Image(systemName: "book.closed").foregroundStyle(PulseTheme.muted)
        }
    }
}

struct PulseCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .background(PulseTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(PulseTheme.border))
    }
}

struct PulsePrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [PulseTheme.orchid, PulseTheme.pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(configuration.isPressed ? 0.75 : 1)
            )
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct PulsePillTab: View {
    let tab: PulseTab
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if active {
                    HStack(spacing: 5) {
                        Image(systemName: tab.glyph)
                        Text(tab.label)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(PulseTheme.orchid.opacity(0.35))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(PulseTheme.orchid))
                } else {
                    Image(systemName: tab.glyph)
                        .font(.body.weight(.semibold))
                        .padding(.vertical, 10)
                }
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(active ? PulseTheme.mint : PulseTheme.muted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }
}

struct PulseScanFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "barcode.viewfinder")
                .font(.title2.weight(.semibold))
                .foregroundStyle(PulseTheme.canvas)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(colors: [PulseTheme.mint, PulseTheme.orchid], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: PulseTheme.orchid.opacity(0.45), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan ISBN")
    }
}
