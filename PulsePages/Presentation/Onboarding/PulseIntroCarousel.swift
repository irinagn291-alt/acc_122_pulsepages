import SwiftUI

struct PulseIntroCarousel: View {
    @Binding var finished: Bool
    @State private var step = 0

    private let slides: [(icon: String, title: String, body: String)] = [
        ("waveform.path.ecg", "Welcome to Pulse Pages", "Your reading rhythm, captured — a living feed of titles that move you."),
        ("magnifyingglass", "Search the Open Library", "Hunt by title, author, or topic. Every query taps the public catalog in real time."),
        ("square.grid.2x2", "Ride the Feed", "Browse curated lanes and subject waves — science, history, poetry, and more."),
        ("barcode.viewfinder", "Scan from the Spine", "Tap the center pulse button to read an ISBN barcode and jump straight to the book."),
        ("square.stack.3d.up", "Build Your Stack", "Pin favorites with journal notes and a five-star pulse rating. Your stack stays on device."),
    ]

    var body: some View {
        ZStack {
            PulseBackdrop()
            VStack(spacing: 0) {
                TabView(selection: $step) {
                    ForEach(slides.indices, id: \.self) { i in
                        slideView(slides[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxHeight: .infinity)

                VStack(spacing: 12) {
                    if step < slides.count - 1 {
                        Button("Continue") { withAnimation { step += 1 } }
                            .buttonStyle(PulsePrimaryButton())
                        Button("Skip intro") { finished = true }
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(PulseTheme.muted)
                    } else {
                        Button("Start pulsing") { finished = true }
                            .buttonStyle(PulsePrimaryButton())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func slideView(_ slide: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(PulseTheme.surface)
                    .frame(width: 120, height: 120)
                    .overlay(Circle().stroke(PulseTheme.border))
                Image(systemName: slide.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(colors: [PulseTheme.pink, PulseTheme.mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            Text(slide.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(PulseTheme.ink)
                .multilineTextAlignment(.center)
            Text(slide.body)
                .font(.body)
                .foregroundStyle(PulseTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
