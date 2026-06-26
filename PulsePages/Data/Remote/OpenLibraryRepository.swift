import Foundation

actor OpenLibraryRepository: BookCatalogGateway {
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = OpenLibraryEndpoints.isolatedSession()) {
        self.session = session
    }

    func searchCatalog(_ phrase: String, limit: Int) async throws -> [CatalogRipple] {
        guard let url = OpenLibraryEndpoints.searchURL(query: phrase, limit: limit) else { throw URLError(.badURL) }
        let (data, resp) = try await fetchWithBackoff(url)
        try Self.verify(resp)
        return try decoder.decode(OLSearchEnvelope.self, from: data).docs.compactMap(mapDoc)
    }

    func fetchDossier(workKey: String) async throws -> BookDossier {
        guard let wURL = OpenLibraryEndpoints.workURL(path: workKey) else { throw URLError(.badURL) }
        let (wData, wResp) = try await fetchWithBackoff(wURL)
        try Self.verify(wResp)
        let work = try decoder.decode(OLWorkEnvelope.self, from: wData)
        let topics = splitTopics(work.subjects)
        let synopsis = work.description?.plainText
        let book = try await hydrateBook(workKey: workKey, work: work, topics: topics)

        async let editions: [BriefBook] = {
            guard let u = OpenLibraryEndpoints.editionsURL(path: workKey) else { return [] }
            do {
                let (d, r) = try await self.fetchWithBackoff(u)
                try Self.verify(r)
                return Self.mapEditions(try self.decoder.decode(OLEditionsEnvelope.self, from: d))
            } catch { return [] }
        }()

        async let echoes: [BriefBook] = {
            guard let anchor = topics.first ?? work.subjects?.first, !anchor.isEmpty,
                  let u = OpenLibraryEndpoints.subjectURL(slug: anchor, limit: 18) else { return [] }
            do {
                let (d, r) = try await self.fetchWithBackoff(u)
                try Self.verify(r)
                return Self.mapSubject(try self.decoder.decode(OLSubjectWorksEnvelope.self, from: d), skip: workKey)
            } catch { return [] }
        }()

        return BookDossier(book: book, synopsis: synopsis, echoes: await echoes, editions: await editions)
    }

    func searchAuthors(_ phrase: String, limit: Int) async throws -> [AuthorGlyph] {
        guard let url = OpenLibraryEndpoints.authorSearchURL(query: phrase, limit: limit) else { throw URLError(.badURL) }
        let (data, resp) = try await fetchWithBackoff(url)
        try Self.verify(resp)
        return (try decoder.decode(OLAuthorSearchEnvelope.self, from: data).docs ?? []).compactMap { doc in
            guard let k = doc.key, let n = doc.name, !n.isEmpty else { return nil }
            return AuthorGlyph(authorKey: k, displayName: n, birthYear: Self.yearFrom(doc.birthDate), signatureTopic: nil)
        }
    }

    func browseSubject(_ slug: String, limit: Int) async throws -> [BriefBook] {
        guard let url = OpenLibraryEndpoints.subjectURL(slug: slug, limit: limit) else { throw URLError(.badURL) }
        let (data, resp) = try await fetchWithBackoff(url)
        try Self.verify(resp)
        return Self.mapSubject(try decoder.decode(OLSubjectWorksEnvelope.self, from: data), skip: nil)
    }

    func resolveISBN(_ digits: String) async throws -> String {
        guard let url = OpenLibraryEndpoints.isbnURL(digits: digits) else { throw URLError(.badURL) }
        let (data, resp) = try await fetchWithBackoff(url)
        if let http = resp as? HTTPURLResponse, http.statusCode == 404 {
            return try await isbnFallback(digits)
        }
        try Self.verify(resp)
        if let ed = try? decoder.decode(OLISBNEditionEnvelope.self, from: data),
           let key = ed.works?.compactMap(\.key).first(where: { $0.contains("works") }) { return key }
        return try await isbnFallback(digits)
    }

    private func isbnFallback(_ digits: String) async throws -> String {
        guard let url = OpenLibraryEndpoints.searchURL(query: "isbn:\(digits)", limit: 12) else { throw URLError(.badURL) }
        let (data, resp) = try await fetchWithBackoff(url)
        try Self.verify(resp)
        guard let first = try decoder.decode(OLSearchEnvelope.self, from: data).docs.compactMap(mapDoc).first else {
            throw NSError(domain: "PulsePages", code: 404, userInfo: [NSLocalizedDescriptionKey: "No catalog match for this ISBN."])
        }
        return first.book.workKey
    }

    private func fetchWithBackoff(_ url: URL) async throws -> (Data, URLResponse) {
        for attempt in 0..<3 {
            let pair = try await session.data(from: url)
            if let http = pair.1 as? HTTPURLResponse, http.statusCode == 503, attempt < 2 {
                try await Task.sleep(nanoseconds: UInt64(350_000_000 + 200_000_000 * UInt64(attempt)))
                continue
            }
            return pair
        }
        throw URLError(.unknown)
    }

    private static func verify(_ resp: URLResponse) throws {
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw URLError(.badServerResponse) }
    }

    private func mapDoc(_ doc: OLSearchDoc) -> CatalogRipple? {
        guard let key = doc.key, key.contains("/works/"), let title = doc.title, !title.isEmpty else { return nil }
        let book = PulseBook(
            workKey: key, headline: title,
            byline: doc.authorName?.joined(separator: ", ") ?? "",
            firstYear: doc.firstPublishYear, coverToken: doc.coverI,
            editionTally: doc.editionCount, topicTags: splitTopics(doc.subject)
        )
        return CatalogRipple(book: book, relevance: nil)
    }

    private func hydrateBook(workKey: String, work: OLWorkEnvelope, topics: [String]) async throws -> PulseBook {
        let title = (work.title ?? "—").trimmingCharacters(in: .whitespacesAndNewlines)
        let keys = work.authors?.compactMap { $0.author?.key }.filter { !$0.isEmpty } ?? []
        var names: [(Int, String)] = []
        if !keys.isEmpty {
            try await withThrowingTaskGroup(of: (Int, String).self) { group in
                for (i, k) in keys.enumerated() {
                    group.addTask {
                        do { return (i, try await self.authorName(k)) }
                        catch { return (i, k.split(separator: "/").last.map(String.init) ?? "Unknown") }
                    }
                }
                for try await pair in group { names.append(pair) }
            }
        }
        let line = names.sorted { $0.0 < $1.0 }.map(\.1).filter { !$0.isEmpty }.joined(separator: ", ")
        return PulseBook(
            workKey: workKey, headline: title, byline: line,
            firstYear: nil, coverToken: work.covers?.first,
            editionTally: nil, topicTags: topics
        )
    }

    private func authorName(_ key: String) async throws -> String {
        guard let url = OpenLibraryEndpoints.authorProfileURL(key: key) else { throw URLError(.badURL) }
        let (data, resp) = try await fetchWithBackoff(url)
        try Self.verify(resp)
        let n = (try decoder.decode(OLAuthorNameEnvelope.self, from: data).name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { throw URLError(.cannotDecodeRawData) }
        return n
    }

    private static func mapEditions(_ env: OLEditionsEnvelope) -> [BriefBook] {
        (env.entries ?? []).compactMap { e in
            guard let k = e.key, let t = e.title, !t.isEmpty else { return nil }
            return BriefBook(workKey: k, headline: t, byline: e.publishDate ?? "",
                             firstYear: yearFrom(e.publishDate), coverToken: e.covers?.first)
        }
    }

    private static func mapSubject(_ env: OLSubjectWorksEnvelope, skip: String?) -> [BriefBook] {
        (env.works ?? []).compactMap { w in
            guard let k = w.key, k.contains("/works/"), let t = w.title, !t.isEmpty else { return nil }
            if let skip, k == skip { return nil }
            let authors = w.authors?.compactMap(\.name).joined(separator: ", ") ?? ""
            return BriefBook(workKey: k, headline: t, byline: authors,
                             firstYear: w.firstPublishYear, coverToken: w.coverId)
        }
    }

    private func splitTopics(_ raw: [String]?) -> [String] {
        guard let raw, !raw.isEmpty else { return [] }
        var out: [String] = []; var seen = Set<String>()
        let sep = CharacterSet(charactersIn: ",;/|")
        for item in raw {
            let softened = item.replacingOccurrences(of: " and ", with: ",", options: .caseInsensitive)
            for seg in softened.components(separatedBy: sep).map({ $0.trimmingCharacters(in: .whitespaces) }).filter({ !$0.isEmpty }) {
                if seen.insert(seg.lowercased()).inserted { out.append(seg) }
            }
        }
        return Array(out.prefix(24))
    }

    private static func yearFrom(_ raw: String?) -> Int? {
        guard let raw else { return nil }
        let digits = raw.compactMap { $0.isNumber ? $0 : nil }
        guard digits.count >= 4 else { return nil }
        return Int(String(digits.prefix(4)))
    }
}
