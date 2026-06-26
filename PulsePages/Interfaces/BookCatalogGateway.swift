import Foundation

protocol BookCatalogGateway: Sendable {
    func searchCatalog(_ phrase: String, limit: Int) async throws -> [CatalogRipple]
    func fetchDossier(workKey: String) async throws -> BookDossier
    func searchAuthors(_ phrase: String, limit: Int) async throws -> [AuthorGlyph]
    func browseSubject(_ slug: String, limit: Int) async throws -> [BriefBook]
    func resolveISBN(_ digits: String) async throws -> String
}
