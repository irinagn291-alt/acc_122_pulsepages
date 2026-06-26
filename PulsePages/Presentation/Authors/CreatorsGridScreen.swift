import SwiftUI

struct CreatorsGridScreen: View {
    @EnvironmentObject private var container: PulseContainer
    @Binding var navPath: NavigationPath
    @State private var lens: CreatorLens = .authors
    @State private var authorQuery = ""
    @State private var authors: [AuthorGlyph] = []
    @State private var subjectBooks: [BriefBook] = []
    @State private var loading = false
    @State private var fault: String?

    private let subjectSlugs: [(label: String, slug: String)] = [
        ("Science Fiction", "science_fiction"), ("History", "history"),
        ("Philosophy", "philosophy"), ("Poetry", "poetry"),
        ("Mystery", "mystery"), ("Biography", "biography"),
        ("Fantasy", "fantasy"), ("Classics", "classics"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Picker("Lens", selection: $lens) {
                Text("Authors").tag(CreatorLens.authors)
                Text("Subjects").tag(CreatorLens.subjects)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)

            if lens == .authors {
                authorPane
            } else {
                subjectPane
            }
        }
        .navigationTitle("Creators")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: lens) { _, new in
            if new == .subjects, subjectBooks.isEmpty { Task { await loadSubject(subjectSlugs[0].slug) } }
        }
    }

    private var authorPane: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Author name…", text: $authorQuery)
                    .padding(10)
                    .background(PulseTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(PulseTheme.border))
                    .foregroundStyle(PulseTheme.ink)
                Button("Find") { Task { await searchAuthors() } }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(PulseTheme.orchid).foregroundStyle(.white)
                    .clipShape(Capsule())
                    .disabled(authorQuery.trimmingCharacters(in: .whitespaces).isEmpty || container.reachability.isOffline)
            }
            .padding(.horizontal, 20)
            contentList
        }
    }

    private var subjectPane: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(subjectSlugs, id: \.slug) { item in
                        Button(item.label) { Task { await loadSubject(item.slug) } }
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(PulseTheme.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(PulseTheme.border))
                            .foregroundStyle(PulseTheme.ink)
                    }
                }
                .padding(.horizontal, 20)
            }
            contentList
        }
    }

    @ViewBuilder
    private var contentList: some View {
        if container.reachability.isOffline {
            PulseEmptyState(headline: "Offline", detail: "Creators need a network connection.", glyph: "wifi.slash")
        } else if loading {
            PulseSpinner()
        } else if let fault {
            PulseFaultCard(message: fault) {
                Task { lens == .authors ? await searchAuthors() : await loadSubject(subjectSlugs[0].slug) }
            }
        } else if lens == .authors {
            List(authors) { author in
                Button {
                    navPath.append(PulseRoute.searchResults(author.displayName))
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(author.displayName).font(.subheadline.weight(.semibold))
                        if let y = author.birthYear {
                            Text("b. \(y)").font(.caption).foregroundStyle(PulseTheme.muted)
                        }
                    }
                }
                .listRowBackground(PulseTheme.canvas)
                .foregroundStyle(PulseTheme.ink)
            }
            .listStyle(.plain).scrollContentBackground(.hidden)
        } else {
            List(subjectBooks) { book in
                Button { navPath.append(PulseRoute.bookDetail(book.workKey)) } label: {
                    HStack(spacing: 12) {
                        CoverTile(token: book.coverToken)
                        VStack(alignment: .leading) {
                            Text(book.headline).font(.subheadline.weight(.semibold))
                            Text(book.byline).font(.caption).foregroundStyle(PulseTheme.muted)
                        }
                    }
                }
                .listRowBackground(PulseTheme.canvas)
                .foregroundStyle(PulseTheme.ink)
            }
            .listStyle(.plain).scrollContentBackground(.hidden)
        }
    }

    @MainActor private func searchAuthors() async {
        loading = true; fault = nil
        do {
            authors = try await container.searchAuthors.invoke(authorQuery.trimmingCharacters(in: .whitespaces))
        } catch { fault = error.localizedDescription; authors = [] }
        loading = false
    }

    @MainActor private func loadSubject(_ slug: String) async {
        loading = true; fault = nil
        do {
            subjectBooks = try await container.browseSubject.invoke(slug: slug)
        } catch { fault = error.localizedDescription; subjectBooks = [] }
        loading = false
    }
}
