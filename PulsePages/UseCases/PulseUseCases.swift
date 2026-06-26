import Foundation

struct SearchCatalogUseCase: Sendable {
    let catalog: any BookCatalogGateway

    func invoke(_ phrase: String, limit: Int = 40) async throws -> [CatalogRipple] {
        try await catalog.searchCatalog(phrase, limit: limit)
    }
}

struct FetchBookDossierUseCase: Sendable {
    let catalog: any BookCatalogGateway

    func invoke(workKey: String) async throws -> BookDossier {
        try await catalog.fetchDossier(workKey: workKey)
    }
}

struct SearchAuthorsUseCase: Sendable {
    let catalog: any BookCatalogGateway

    func invoke(_ phrase: String, limit: Int = 20) async throws -> [AuthorGlyph] {
        try await catalog.searchAuthors(phrase, limit: limit)
    }
}

struct BrowseSubjectUseCase: Sendable {
    let catalog: any BookCatalogGateway

    func invoke(slug: String, limit: Int = 24) async throws -> [BriefBook] {
        try await catalog.browseSubject(slug, limit: limit)
    }
}

struct ResolveISBNUseCase: Sendable {
    let catalog: any BookCatalogGateway

    func invoke(_ digits: String) async throws -> String {
        try await catalog.resolveISBN(digits)
    }
}

@MainActor
struct ManageStackUseCase {
    let vault: any StackVaultGateway

    func pin(_ book: PulseBook, note: String? = nil, rating: Int? = nil) -> StackPinResult {
        vault.pinBook(book, note: note, rating: rating)
    }

    func revise(workKey: String, note: String, rating: Int?) {
        vault.updateMark(workKey: workKey, note: note, rating: rating)
    }

    func unpin(_ mark: StackMark) {
        vault.removeMark(mark)
    }

    func pinned(workKey: String) -> Bool {
        vault.isPinned(workKey: workKey)
    }
}
