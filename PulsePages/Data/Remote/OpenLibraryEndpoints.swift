import Foundation

enum OpenLibraryEndpoints {
    private static let host = "openlibrary.org"

    static func isolatedSession() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 28
        cfg.timeoutIntervalForResource = 45
        cfg.waitsForConnectivity = true
        cfg.httpMaximumConnectionsPerHost = 4
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.urlCache = nil
        cfg.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "PulsePages/1.0 (iOS; bundle io.readpulse.pages)",
        ]
        return URLSession(configuration: cfg)
    }

    static func searchURL(query: String, limit: Int) -> URL? {
        var c = URLComponents()
        c.scheme = "https"; c.host = host; c.path = "/search.json"
        c.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "limit", value: String(limit))]
        return c.url
    }

    static func workURL(path: String) -> URL? {
        let t = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "https://\(host)/\(t).json")
    }

    static func editionsURL(path: String) -> URL? {
        let t = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "https://\(host)/\(t)/editions.json?limit=24")
    }

    static func subjectURL(slug: String, limit: Int) -> URL? {
        let enc = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
        return URL(string: "https://\(host)/subjects/\(enc).json?limit=\(limit)")
    }

    static func authorSearchURL(query: String, limit: Int) -> URL? {
        var c = URLComponents()
        c.scheme = "https"; c.host = host; c.path = "/search/authors.json"
        c.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "limit", value: String(limit))]
        return c.url
    }

    static func isbnURL(digits: String) -> URL? {
        let d = digits.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !d.isEmpty, d.allSatisfy(\.isNumber) else { return nil }
        return URL(string: "https://\(host)/isbn/\(d).json")
    }

    static func authorProfileURL(key: String) -> URL? {
        let t = key.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let suffix = t.hasPrefix("authors/") ? t : "authors/\(t)"
        return URL(string: "https://\(host)/\(suffix).json")
    }

    static func coverURL(token: Int, size: String = "M") -> URL? {
        URL(string: "https://covers.openlibrary.org/b/id/\(token)-\(size).jpg")
    }
}
