import SwiftUI

struct BookDetailScreen: View {
    @EnvironmentObject private var container: PulseContainer
    let workKey: String
    @Binding var navPath: NavigationPath

    @State private var dossier: BookDossier?
    @State private var loading = true
    @State private var fault: String?
    @State private var noteDraft = ""
    @State private var ratingDraft: Int?
    @State private var pinnedAlert = false
    @State private var showScanner = false
    @State private var scanAlert: String?

    var body: some View {
        Group {
            if container.reachability.isOffline {
                PulseEmptyState(headline: "Offline", detail: "Book details need a network connection.", glyph: "wifi.slash")
            } else if loading {
                PulseSpinner("Loading book…")
            } else if let fault {
                PulseFaultCard(message: fault) { Task { await load() } }
            } else if let dossier {
                detailBody(dossier)
            } else {
                PulseEmptyState(headline: "Not found", detail: "This book could not be loaded.", glyph: "exclamationmark.triangle")
            }
        }
        .navigationTitle("Book Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Scan") { showScanner = true }
                    .disabled(container.reachability.isOffline)
            }
        }
        .sheet(isPresented: $showScanner) {
            NavigationStack {
                ISBNPulseScanner(isPresented: $showScanner) { digits in
                    Task { await handleISBN(digits) }
                }
            }
        }
        .alert("Pinned", isPresented: $pinnedAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text("Book added to your stack.") }
        .alert("ISBN", isPresented: Binding(get: { scanAlert != nil }, set: { if !$0 { scanAlert = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(scanAlert ?? "") }
        .task(id: workKey) { await load() }
    }

    @ViewBuilder
    private func detailBody(_ d: BookDossier) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    CoverTile(token: d.book.coverToken, width: 96, height: 140)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(d.book.headline).font(.title3.weight(.bold))
                        Text(d.book.byline).font(.footnote).foregroundStyle(PulseTheme.muted)
                    }
                }

                if !d.book.topicTags.isEmpty {
                    labelRow("Topics")
                    FlowTagRow(tags: d.book.topicTags)
                }

                if let synopsis = d.synopsis?.strippingMarkup(), !synopsis.isEmpty {
                    labelRow("Synopsis")
                    Text(synopsis).font(.footnote).foregroundStyle(PulseTheme.ink.opacity(0.85))
                }

                Button(action: { pin(d.book) }) {
                    Label(
                        container.manageStack.pinned(workKey: d.book.workKey) ? "Already pinned" : "Pin to stack",
                        systemImage: container.manageStack.pinned(workKey: d.book.workKey) ? "checkmark.circle.fill" : "plus.circle"
                    )
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background {
                        if container.manageStack.pinned(workKey: d.book.workKey) {
                            PulseTheme.surface
                        } else {
                            LinearGradient(colors: [PulseTheme.orchid, PulseTheme.pink], startPoint: .leading, endPoint: .trailing)
                        }
                    }
                    .foregroundStyle(container.manageStack.pinned(workKey: d.book.workKey) ? PulseTheme.muted : .white)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(container.manageStack.pinned(workKey: d.book.workKey))

                if container.manageStack.pinned(workKey: d.book.workKey) {
                    journalBlock(d.book)
                }

                if !d.echoes.isEmpty {
                    labelRow("Similar")
                    ForEach(d.echoes) { book in slimRow(book) }
                }

                if !d.editions.isEmpty {
                    labelRow("Editions")
                    ForEach(d.editions) { book in slimRow(book) }
                }
            }
            .padding(20)
        }
    }

    private func labelRow(_ t: String) -> some View {
        Text(t.uppercased()).font(.caption.weight(.bold)).foregroundStyle(PulseTheme.pink).tracking(1)
    }

    private func slimRow(_ book: BriefBook) -> some View {
        Button { navPath.append(PulseRoute.bookDetail(book.workKey)) } label: {
            HStack(spacing: 12) {
                CoverTile(token: book.coverToken)
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.headline).font(.subheadline.weight(.semibold))
                    Text(book.byline).font(.caption).foregroundStyle(PulseTheme.muted)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(PulseTheme.ink)
    }

    @ViewBuilder
    private func journalBlock(_ book: PulseBook) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            labelRow("Journal")
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { s in
                    Button { ratingDraft = s } label: {
                        Image(systemName: (ratingDraft ?? 0) >= s ? "star.fill" : "star")
                            .foregroundStyle(PulseTheme.mint)
                    }.buttonStyle(.plain)
                }
                Button("Clear") { ratingDraft = nil }
                    .font(.caption).foregroundStyle(PulseTheme.pink)
            }
            TextEditor(text: $noteDraft)
                .frame(minHeight: 100)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(PulseTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(PulseTheme.border))
                .foregroundStyle(PulseTheme.ink)
            Button("Save journal") {
                container.manageStack.revise(workKey: book.workKey, note: noteDraft, rating: ratingDraft)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(PulseTheme.mint.opacity(0.15))
            .foregroundStyle(PulseTheme.mint)
            .clipShape(Capsule())
        }
        .onAppear { syncDraft(book) }
        .onChange(of: container.stackVault.marks) { _, _ in syncDraft(book) }
    }

    private func pin(_ book: PulseBook) {
        if container.manageStack.pin(book) == .freshPin { pinnedAlert = true }
        syncDraft(book)
    }

    private func syncDraft(_ book: PulseBook) {
        guard let mark = container.stackVault.marks.first(where: { $0.workKey == book.workKey }) else {
            noteDraft = ""; ratingDraft = nil; return
        }
        noteDraft = mark.journalNote; ratingDraft = mark.pulseRating
    }

    @MainActor private func load() async {
        guard !container.reachability.isOffline else { loading = false; return }
        loading = true; fault = nil
        do {
            dossier = try await container.fetchDossier.invoke(workKey: workKey)
            if let d = dossier { syncDraft(d.book) }
        } catch {
            fault = error.localizedDescription; dossier = nil
        }
        loading = false
    }

    @MainActor private func handleISBN(_ digits: String) async {
        do {
            navPath.append(PulseRoute.bookDetail(try await container.resolveISBN.invoke(digits)))
        } catch { scanAlert = error.localizedDescription }
    }
}

private struct FlowTagRow: View {
    let tags: [String]
    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag).font(.caption2.weight(.medium))
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(PulseTheme.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(PulseTheme.border))
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, pt) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pt.x, y: bounds.minY + pt.y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        var positions: [CGPoint] = []
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > maxW, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowH = max(rowH, sz.height); x += sz.width + spacing
        }
        return (CGSize(width: maxW, height: y + rowH), positions)
    }
}

private extension String {
    func strippingMarkup() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
