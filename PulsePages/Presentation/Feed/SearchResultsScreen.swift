import SwiftUI

@MainActor
final class SearchResultsViewModel: ObservableObject {
    @Published var ripples: [CatalogRipple] = []
    @Published var loading = true
    @Published var fault: String?
    @Published var sortWave: SortWave = .natural

    func load(query: String, useCase: SearchCatalogUseCase) async {
        loading = true; fault = nil
        do {
            ripples = try await useCase.invoke(query, limit: 48)
            applySort()
        } catch {
            fault = error.localizedDescription
            ripples = []
        }
        loading = false
    }

    func applySort() {
        switch sortWave {
        case .natural: break
        case .chronology:
            ripples.sort { ($0.book.firstYear ?? 0) > ($1.book.firstYear ?? 0) }
        case .editionCount:
            ripples.sort { ($0.book.editionTally ?? 0) > ($1.book.editionTally ?? 0) }
        }
    }
}

struct SearchResultsScreen: View {
    @EnvironmentObject private var container: PulseContainer
    let queryPhrase: String
    @Binding var navPath: NavigationPath
    @StateObject private var model = SearchResultsViewModel()

    var body: some View {
        Group {
            if container.reachability.isOffline {
                PulseEmptyState(headline: "Offline", detail: "Reconnect to search the catalog.", glyph: "wifi.slash")
            } else if model.loading {
                PulseSpinner("Searching catalog…")
            } else if let fault = model.fault {
                PulseFaultCard(message: fault) {
                    Task { await model.load(query: queryPhrase, useCase: container.searchCatalog) }
                }
            } else if model.ripples.isEmpty {
                PulseEmptyState(headline: "No matches", detail: "Try a broader phrase or another topic lane.", glyph: "doc.text.magnifyingglass")
            } else {
                List(model.ripples) { ripple in
                    Button {
                        navPath.append(PulseRoute.bookDetail(ripple.book.workKey))
                    } label: {
                        HStack(spacing: 12) {
                            CoverTile(token: ripple.book.coverToken)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ripple.book.headline).font(.subheadline.weight(.semibold))
                                Text(ripple.book.byline).font(.caption).foregroundStyle(PulseTheme.muted)
                                if let y = ripple.book.firstYear {
                                    Text(String(y)).font(.caption2).foregroundStyle(PulseTheme.pink)
                                }
                            }
                        }
                    }
                    .listRowBackground(PulseTheme.canvas)
                    .foregroundStyle(PulseTheme.ink)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(queryPhrase)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Picker("Sort", selection: $model.sortWave) {
                    Text("Relevance").tag(SortWave.natural)
                    Text("Year").tag(SortWave.chronology)
                    Text("Editions").tag(SortWave.editionCount)
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
        .onChange(of: model.sortWave) { _, _ in model.applySort() }
        .task(id: queryPhrase) {
            await model.load(query: queryPhrase, useCase: container.searchCatalog)
        }
    }
}
