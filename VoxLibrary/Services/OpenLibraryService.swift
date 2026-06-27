//
//  OpenLibraryService.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  OpenLibraryService.swift
//  VoxLibrary
//

import Foundation

final class OpenLibraryService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch trending books (daily). No API key required.
    func fetchTrending(limit: Int = 20) async throws -> [OLWork] {
        let urlString = "\(APIConfig.openLibraryBase)/trending/daily.json?limit=\(limit)"
        guard let url = URL(string: urlString) else { throw OLError.invalidURL }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OLError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let decoded = try JSONDecoder().decode(OpenLibraryTrendingResponse.self, from: data)
        return decoded.works ?? []
    }

    /// Convert an OLWork to a DiscoverBook
    func toDiscoverBook(_ work: OLWork) -> DiscoverBook? {
        guard let title = work.title else { return nil }

        // Update toDiscoverBook(_:) method:
        let coverURL: URL? = work.coverI.flatMap {
            URL(string: "https://covers.openlibrary.org/b/id/\($0)-L.jpg")
        }

        let year = work.firstPublishYear.map { "\($0)" }

        return DiscoverBook(
            id: DiscoverBook.generateID(isbn13: nil, olKey: work.key, title: title, author: work.authorName?.first),
            title: title,
            subtitle: nil,
            authors: work.authorName ?? [],
            coverURL: coverURL,
            description: nil,
            publisher: nil,
            publishDate: year,
            pageCount: nil,
            categories: work.subject,
            averageRating: nil,
            ratingsCount: nil,
            isbn13: nil,
            isbn10: nil,
            previewLink: work.key.map { "\(APIConfig.openLibraryBase)\($0)" },
            infoLink: work.key.map { "\(APIConfig.openLibraryBase)\($0)" },
            openLibraryKey: work.key,
            source: .openLibrary,
            listName: nil,
            rank: nil
        )
    }

    enum OLError: LocalizedError {
        case invalidURL
        case httpError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid Open Library URL"
            case .httpError(let code): return "Open Library returned HTTP \(code)"
            }
        }
    }
}
