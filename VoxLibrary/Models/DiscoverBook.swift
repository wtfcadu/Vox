//
//  DiscoverBook.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  DiscoverBook.swift
//  VoxLibrary
//

import Foundation

// MARK: - Unified Discover Book Model

struct DiscoverBook: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var title: String
    var subtitle: String?
    var authors: [String]
    var coverURL: URL?
    var description: String?
    var publisher: String?
    var publishDate: String?
    var pageCount: Int?
    var categories: [String]?
    var averageRating: Double?
    var ratingsCount: Int?
    var isbn13: String?
    var isbn10: String?
    var previewLink: String?
    var infoLink: String?
    var openLibraryKey: String?
    var source: BookSource
    var listName: String?
    var rank: Int?

    enum BookSource: String, Codable, Sendable {
        case nyt, googleBooks, openLibrary
    }

    /// Stable ID generation: prefer ISBN13, then OL key, then title+author hash
    static func generateID(isbn13: String?, olKey: String?, title: String, author: String?) -> String {
        if let isbn13, !isbn13.isEmpty { return "isbn_\(isbn13)" }
        if let olKey, !olKey.isEmpty { return "ol_\(olKey)" }
        let combined = "\(title)_\(author ?? "")"
        return "hash_\(combined.hashValue.description)"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DiscoverBook, rhs: DiscoverBook) -> Bool { lhs.id == rhs.id }
}

// MARK: - NYT Books API Response Models

struct NYTListResponse: Codable, Sendable {
    let results: NYTListResults?
}

struct NYTListResults: Codable, Sendable {
    let books: [NYTBook]?
}

struct NYTBook: Codable, Sendable {
    let title: String?
    let author: String?
    let bookImage: String?
    let publisher: String?
    let description: String?
    let isbn13: String?
    let isbn10: String?
    let rank: Int?
    let amazonProductURL: String?
    let buyLinks: [NYTBuyLink]?
}

struct NYTBuyLink: Codable, Sendable {
    let name: String?
    let url: String?
}

// MARK: - Google Books API Response Models

struct GoogleVolumesResponse: Codable, Sendable {
    let items: [GoogleVolume]?
    let totalItems: Int?
}

struct GoogleVolume: Codable, Sendable {
    let id: String?
    let volumeInfo: GoogleVolumeInfo?
    let accessInfo: GoogleAccessInfo?
}

struct GoogleVolumeInfo: Codable, Sendable {
    let title: String?
    let subtitle: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let averageRating: Double?
    let ratingsCount: Int?
    let imageLinks: GoogleImageLinks?
    let industryIdentifiers: [GoogleIndustryIdentifier]?
    let previewLink: String?
    let infoLink: String?
}

struct GoogleImageLinks: Codable, Sendable {
    let smallThumbnail: String?
    let thumbnail: String?
    /// Higher-res cover; not always present
    let extraLarge: String?
    let large: String?
    let medium: String?
}

struct GoogleIndustryIdentifier: Codable, Sendable {
    let type: String?
    let identifier: String?
}

struct GoogleAccessInfo: Codable, Sendable {
    let epub: GoogleEpubAccess?
    let pdf: GooglePdfAccess?
}

struct GoogleEpubAccess: Codable, Sendable {
    let isAvailable: Bool?
    let downloadLink: String?
}

struct GooglePdfAccess: Codable, Sendable {
    let isAvailable: Bool?
    let downloadLink: String?
}

// MARK: - Open Library Trending Response Models

struct OpenLibraryTrendingResponse: Codable, Sendable {
    let works: [OLWork]?
}

struct OLWork: Codable, Sendable {
    let key: String?
    let title: String?
    let authorKey: [String]?
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let subject: [String]?
    let editionCount: Int?
}
