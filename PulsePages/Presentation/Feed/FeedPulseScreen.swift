import SwiftUI

struct FeedPulseScreen: View {
    @EnvironmentObject private var container: PulseContainer
    @Binding var navPath: NavigationPath
    var onScanTap: () -> Void

    @State private var phrase = ""

    private let topicChips: [(label: String, query: String)] = [
        ("Sci-Fi", "subject:science fiction"), ("History", "subject:world history"),
        ("Mystery", "subject:mystery"), ("Philosophy", "subject:philosophy"),
        ("Poetry", "subject:poetry"), ("Biography", "subject:biography"),
        ("Fantasy", "subject:fantasy"), ("Essays", "subject:essays"),
    ]

    private let waves: [(title: String, blurb: String, query: String)] = [
        ("Neon Futures", "Cyberpunk and speculative frontiers", "cyberpunk science fiction"),
        ("Quiet Classics", "Timeless prose worth revisiting", "classic literature"),
        ("Pulse Picks", "Award-season standouts", "award winning novels"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Feed")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(PulseTheme.ink)
                    Text("Search, browse subjects, or ride a curated wave.")
                        .font(.subheadline)
                        .foregroundStyle(PulseTheme.muted)
                }

                HStack(spacing: 10) {
                    TextField("Title, author, topic…", text: $phrase)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(PulseTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(PulseTheme.border))
                        .foregroundStyle(PulseTheme.ink)
                    Button(action: runSearch) {
                        Image(systemName: "magnifyingglass")
                            .padding(12)
                            .background(PulseTheme.orchid)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(phrase.trimmingCharacters(in: .whitespaces).isEmpty || container.reachability.isOffline)
                }

                PulseCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Open Library pulse", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(PulseTheme.mint)
                        Text("Live catalog queries — your stack and notes never leave this device.")
                            .font(.footnote)
                            .foregroundStyle(PulseTheme.muted)
                    }
                }

                sectionLabel("Topic lanes")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(topicChips, id: \.label) { chip in
                            Button {
                                guard !container.reachability.isOffline else { return }
                                navPath.append(PulseRoute.searchResults(chip.query))
                            } label: {
                                Text(chip.label)
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(PulseTheme.canvas)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(PulseTheme.orchid.opacity(0.5)))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(PulseTheme.ink)
                        }
                    }
                }

                sectionLabel("Curated waves")
                VStack(spacing: 10) {
                    ForEach(waves, id: \.title) { wave in
                        Button {
                            guard !container.reachability.isOffline else { return }
                            navPath.append(PulseRoute.searchResults(wave.query))
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "waveform.path")
                                    .foregroundStyle(PulseTheme.pink)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(wave.title).font(.subheadline.weight(.semibold))
                                    Text(wave.blurb).font(.caption).foregroundStyle(PulseTheme.muted)
                                }
                                Spacer()
                            }
                            .foregroundStyle(PulseTheme.ink)
                        }
                        .buttonStyle(.plain)
                        .padding(12)
                        .background(PulseTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(PulseTheme.border))
                    }
                }

                Button(action: onScanTap) {
                    Label("Or scan an ISBN barcode", systemImage: "barcode.viewfinder")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(PulseTheme.mint.opacity(0.12))
                        .foregroundStyle(PulseTheme.mint)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(PulseTheme.mint.opacity(0.35)))
                }
                .buttonStyle(.plain)
                .disabled(container.reachability.isOffline)
            }
            .padding(20)
        }
        .navigationBarHidden(true)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(PulseTheme.pink)
            .tracking(1.2)
    }

    private func runSearch() {
        let q = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        navPath.append(PulseRoute.searchResults(q))
    }
}
