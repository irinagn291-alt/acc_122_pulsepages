import Foundation

struct OLSearchEnvelope: Decodable, Sendable {
    let docs: [OLSearchDoc]
    enum CodingKeys: String, CodingKey { case docs }
}

struct OLSearchDoc: Decodable, Sendable {
    let key: String?
    let title: String?
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let editionCount: Int?
    let subject: [String]?
    enum CodingKeys: String, CodingKey {
        case key, title, subject
        case authorName = "author_name"
        case firstPublishYear = "first_publish_year"
        case coverI = "cover_i"
        case editionCount = "edition_count"
    }
}

struct OLWorkEnvelope: Decodable, Sendable {
    let title: String?
    let authors: [OLAuthorStub]?
    let description: OLDescriptionUnion?
    let subjects: [String]?
    let covers: [Int]?
    struct OLAuthorStub: Decodable, Sendable {
        let author: OLAuthorRef?
        struct OLAuthorRef: Decodable, Sendable { let key: String? }
    }
    enum OLDescriptionUnion: Decodable, Sendable {
        case text(String)
        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self) { self = .text(s); return }
            struct Obj: Decodable { let value: String? }
            self = .text(try c.decode(Obj.self).value ?? "")
        }
        var plainText: String? {
            if case .text(let v) = self { return v.isEmpty ? nil : v }
            return nil
        }
    }
}

struct OLEditionsEnvelope: Decodable, Sendable {
    let entries: [OLEditionEntry]?
    struct OLEditionEntry: Decodable, Sendable {
        let key: String?
        let title: String?
        let publishDate: String?
        let covers: [Int]?
        enum CodingKeys: String, CodingKey {
            case key, title, covers
            case publishDate = "publish_date"
        }
    }
}

struct OLSubjectWorksEnvelope: Decodable, Sendable {
    let works: [OLSubjectWork]?
    struct OLSubjectWork: Decodable, Sendable {
        let key: String?
        let title: String?
        let authors: [OLSubjectAuthor]?
        let coverId: Int?
        let firstPublishYear: Int?
        enum CodingKeys: String, CodingKey {
            case key, title, authors
            case coverId = "cover_id"
            case firstPublishYear = "first_publish_year"
        }
        struct OLSubjectAuthor: Decodable, Sendable { let name: String? }
    }
}

struct OLAuthorNameEnvelope: Decodable, Sendable { let name: String? }

struct OLAuthorSearchEnvelope: Decodable, Sendable {
    let docs: [OLAuthorDoc]?
    struct OLAuthorDoc: Decodable, Sendable {
        let key: String?
        let name: String?
        let birthDate: String?
        enum CodingKeys: String, CodingKey {
            case key, name
            case birthDate = "birth_date"
        }
    }
}

struct OLISBNEditionEnvelope: Decodable, Sendable {
    struct WorkRef: Decodable, Sendable { let key: String? }
    let works: [WorkRef]?
}
