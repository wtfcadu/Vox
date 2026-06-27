//
//  NYTBooksService.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  NYTBooksService.swift
//  VoxLibrary
//

import Foundation

final class NYTBooksService: Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch a single best-seller list by list name.
    /// Common list names: "hardcover-fiction", "hardcover-nonfiction",
    /// "combined-print-and-e-book-fiction", "paperback-nonfiction",
    /// "young-adult", "mass-market-paperback"
    func fetchList(named listName: String) async throws -> [NYTBook] {
        guard let apiKey = APIConfig.nytApiKey else {
            throw NYTError.noApiKey
        }

        let urlString = "\(APIConfig.nytBooksBase)/lists/current/\(listName).json?api-key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw NYTError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NYTError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }

        let decoded = try JSONDecoder().decode(NYTListResponse.self, from: data)
        return decoded.results?.books ?? []
    }

    enum NYTError: LocalizedError {
        case noApiKey
        case invalidURL
        case httpError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .noApiKey: return "NYT API key not configured. Set it in APIConfig.swift"
            case .invalidURL: return "Invalid NYT API URL"
            case .httpError(let code): return "NYT API returned HTTP \(code)"
            }
        }
    }
}