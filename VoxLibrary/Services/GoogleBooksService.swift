//
//  GoogleBooksService.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  GoogleBooksService.swift
//  VoxLibrary
//

import Foundation

final class GoogleBooksService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Search by ISBN (exact match — best for enriching NYT results)
    func lookupByISBN(_ isbn: String) async throws -> GoogleVolume? {
        let query = "isbn:\(isbn)"
        let volumes = try await search(query: query, maxResults: 1)
        return volumes.first
    }

    /// General search query
    func search(query: String, maxResults: Int = 15, orderBy: String? = nil) async throws -> [GoogleVolume] {
        var components = URLComponents(string: "\(APIConfig.googleBooksBase)/volumes")!
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "printType", value: "books")
        ]
        if let orderBy { items.append(URLQueryItem(name: "orderBy", value: orderBy)) }
        components.queryItems = items

        guard let url = components.url else { throw GoogleError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GoogleError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let decoded = try JSONDecoder().decode(GoogleVolumesResponse.self, from: data)
        return decoded.items ?? []
    }

    /// Enrich a DiscoverBook (from NYT or OL) with Google Books metadata
    func enrich(_ book: inout DiscoverBook, isbn: String?) async {
        let query: String
        if let isbn, !isbn.isEmpty {
            query = "isbn:\(isbn)"
        } else {
            // Fallback: search by title + first author
            let author = book.authors.first ?? ""
            query = "\"\(book.title)\" \(author)"
        }

        do {
            let results = try await search(query: query, maxResults: 3)
            guard let best = results.first, let info = best.volumeInfo else { return }

            // Only fill in fields that are missing
            if book.description == nil || book.description?.isEmpty == true {
                book.description = info.description
            }
            if book.pageCount == nil { book.pageCount = info.pageCount }
            if book.categories == nil || book.categories?.isEmpty == true {
                book.categories = info.categories
            }
            if book.averageRating == nil { book.averageRating = info.averageRating }
            if book.ratingsCount == nil { book.ratingsCount = info.ratingsCount }
            if book.subtitle == nil { book.subtitle = info.subtitle }
            if book.publisher == nil { book.publisher = info.publisher }
            if book.publishDate == nil { book.publishDate = info.publishedDate }
            if book.previewLink == nil { book.previewLink = info.previewLink }
            if book.infoLink == nil { book.infoLink = info.infoLink }

            // Prefer higher-res cover from Google
            if book.coverURL == nil, let links = info.imageLinks {
                book.coverURL = bestCoverURL(from: links)
            }

            // Fill ISBNs if missing
            if book.isbn13 == nil || book.isbn10 == nil {
                for id in info.industryIdentifiers ?? [] {
                    if id.type == "ISBN_13", book.isbn13 == nil { book.isbn13 = id.identifier }
                    if id.type == "ISBN_10", book.isbn10 == nil { book.isbn10 = id.identifier }
                }
            }
        } catch {
            print("[GoogleBooksService] Enrichment failed for \(book.title): \(error)")
        }
    }

    /// Pick the highest-resolution cover available
    private func bestCoverURL(from links: GoogleImageLinks) -> URL? {
        // Order: extraLarge > large > medium > thumbnail > smallThumbnail
        let priorities: [String?] = [links.extraLarge, links.large, links.medium, links.thumbnail, links.smallThumbnail]
        for raw in priorities {
            if let raw, !raw.isEmpty {
                // Google sometimes returns HTTP; force HTTPS
                let fixed = raw.replacingOccurrences(of: "http://", with: "https://")
                // Replace edgeCrop with zoom to get full cover
                let zoomed = fixed.replacingOccurrences(of: "edge=curl", with: "zoom=1")
                return URL(string: zoomed)
            }
        }
        return nil
    }

    /// Convert a GoogleVolume to a DiscoverBook
    func toDiscoverBook(_ volume: GoogleVolume, source: DiscoverBook.BookSource = .googleBooks, listName: String? = nil, rank: Int? = nil) -> DiscoverBook? {
        guard let info = volume.volumeInfo, let title = info.title else { return nil }

        let isbn13 = info.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
        let isbn10 = info.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier

        return DiscoverBook(
            id: DiscoverBook.generateID(isbn13: isbn13, olKey: nil, title: title, author: info.authors?.first),
            title: title,
            subtitle: info.subtitle,
            authors: info.authors ?? [],
            coverURL: info.imageLinks.flatMap { bestCoverURL(from: $0) },
            description: info.description,
            publisher: info.publisher,
            publishDate: info.publishedDate,
            pageCount: info.pageCount,
            categories: info.categories,
            averageRating: info.averageRating,
            ratingsCount: info.ratingsCount,
            isbn13: isbn13,
            isbn10: isbn10,
            previewLink: info.previewLink,
            infoLink: info.infoLink,
            source: source,
            listName: listName,
            rank: rank
        )
    }

    enum GoogleError: LocalizedError {
        case invalidURL
        case httpError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Google Books API URL"
            case .httpError(let code): return "Google Books API returned HTTP \(code)"
            }
        }
    }
}