import Foundation

struct PulseBook: Identifiable, Hashable, Codable, Sendable {
    var id: String { workKey }
    let workKey: String
    let headline: String
    let byline: String
    let firstYear: Int?
    let coverToken: Int?
    let editionTally: Int?
    let topicTags: [String]
}

struct StackMark: Identifiable, Hashable, Sendable {
    let id: UUID
    let workKey: String
    var headline: String
    var byline: String
    let pinnedAt: Date
    var journalNote: String
    var pulseRating: Int?

    enum CodingKeys: String, CodingKey {
        case id, workKey, headline, byline, pinnedAt, journalNote, pulseRating
    }
}

extension StackMark: Codable {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        workKey = try c.decode(String.self, forKey: .workKey)
        headline = try c.decode(String.self, forKey: .headline)
        byline = try c.decode(String.self, forKey: .byline)
        pinnedAt = try c.decode(Date.self, forKey: .pinnedAt)
        journalNote = try c.decodeIfPresent(String.self, forKey: .journalNote) ?? ""
        pulseRating = try c.decodeIfPresent(Int.self, forKey: .pulseRating)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(workKey, forKey: .workKey)
        try c.encode(headline, forKey: .headline)
        try c.encode(byline, forKey: .byline)
        try c.encode(pinnedAt, forKey: .pinnedAt)
        try c.encode(journalNote, forKey: .journalNote)
        try c.encodeIfPresent(pulseRating, forKey: .pulseRating)
    }
}

struct CatalogRipple: Identifiable, Hashable, Sendable {
    var id: String { book.workKey }
    let book: PulseBook
    let relevance: Double?
}

struct AuthorGlyph: Identifiable, Hashable, Codable, Sendable {
    var id: String { authorKey }
    let authorKey: String
    let displayName: String
    let birthYear: Int?
    let signatureTopic: String?
}

struct BriefBook: Identifiable, Hashable, Codable, Sendable {
    var id: String { workKey }
    let workKey: String
    let headline: String
    let byline: String
    let firstYear: Int?
    let coverToken: Int?
}

struct BookDossier: Hashable, Sendable {
    let book: PulseBook
    let synopsis: String?
    let echoes: [BriefBook]
    let editions: [BriefBook]
}

enum SortWave: String, CaseIterable, Identifiable, Hashable, Sendable {
    case natural, chronology, editionCount
    var id: String { rawValue }
}

enum CreatorLens: String, CaseIterable, Identifiable, Hashable, Sendable {
    case authors, subjects
    var id: String { rawValue }
}

enum StackPinResult: Equatable, Sendable {
    case freshPin, refreshedPin
}

enum PulseRoute: Hashable {
    case searchResults(String)
    case bookDetail(String)
}

enum PulseTab: String, CaseIterable, Identifiable, Hashable {
    case feed, stack, creators
    var id: String { rawValue }

    var label: String {
        switch self {
        case .feed: "Feed"
        case .stack: "Stack"
        case .creators: "Creators"
        }
    }

    var glyph: String {
        switch self {
        case .feed: "waveform.path"
        case .stack: "square.stack.3d.up"
        case .creators: "person.3"
        }
    }
}
