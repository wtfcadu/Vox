

//
//  ForYouViewModel.swift
//  VoxLibrary
//

import Foundation
import SwiftUI

/// A single horizontal carousel row on the "For You" screen.
struct CarouselSection: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String?
    var books: [DiscoverBook]
    var isLoading: Bool
    var error: String?
}

@MainActor
@Observable
final class ForYouViewModel {
    var sections: [CarouselSection] = []
    var isLoadingInitial = false
    var errorMessage: String?
    var lastRefreshed: Date?

    private let nytService = NYTBooksService()
    private let googleService = GoogleBooksService()
    private let olService = OpenLibraryService()
    private let cache = RecommendationsCacheService.shared

    /// Define our carousel rows and their data sources
    private let carouselDefinitions: [(id: String, title: String, subtitle: String?, source: CarouselSource)] = [
        ("nyt_fiction",    "NYT Best Sellers — Fiction",     "Updated weekly",    .nytList("hardcover-fiction")),
        ("nyt_nonfiction", "NYT Best Sellers — Non-Fiction", "Updated weekly",    .nytList("hardcover-nonfiction")),
        ("trending",       "Trending Now",                   "From Open Library", .openLibraryTrending),
        ("classics",       "Highly Rated Classics",          "Timeless favorites", .googleSearch("subject:classics", orderBy: "relevance")),
        ("scifi",          "Science Fiction Essentials",     "Explore new worlds", .googleSearch("subject:\"science fiction\"", orderBy: "relevance")),
        ("mystery",        "Mystery & Thriller",             "Page-turners",       .googleSearch("subject:mystery+thriller", orderBy: "relevance")),
        ("selfhelp",       "Self-Help & Wellness",           "Better living",      .googleSearch("subject:\"self-help\"", orderBy: "relevance")),
        ("nonfiction",     "Popular Non-Fiction",            "Learn something new", .googleSearch("subject:nonfiction", orderBy: "newest")),
    ]

    enum CarouselSource: Sendable {
        case nytList(String)       // list name
        case openLibraryTrending
        case googleSearch(String, orderBy: String?)
    }

    func loadAllSections(forceRefresh: Bool = false) async {
        // If already loaded and not forcing refresh, skip
        if !sections.isEmpty && !forceRefresh { return }

        isLoadingInitial = true
        errorMessage = nil

        // Initialize sections as loading
        sections = carouselDefinitions.map { def in
            CarouselSection(id: def.id, title: def.title, subtitle: def.subtitle, books: [], isLoading: true, error: nil)
        }

        // Load all carousels concurrently
        await withTaskGroup(of: (String, [DiscoverBook], String?).self) { group in
            for def in carouselDefinitions {
                group.addTask {
                    await self.loadCarousel(def: def, forceRefresh: forceRefresh)
                }
            }
            for await result in group {
                if let idx = sections.firstIndex(where: { $0.id == result.0 }) {
                    if let error = result.2 {
                        sections[idx] = CarouselSection(
                            id: result.0,
                            title: sections[idx].title,
                            subtitle: sections[idx].subtitle,
                            books: [],
                            isLoading: false,
                            error: error
                        )
                    } else {
                        sections[idx] = CarouselSection(
                            id: result.0,
                            title: sections[idx].title,
                            subtitle: sections[idx].subtitle,
                            books: result.1,
                            isLoading: false,
                            error: nil
                        )
                    }
                }
            }
        }

        isLoadingInitial = false
        lastRefreshed = Date()
    }

    /// Load books for a single carousel, with caching
    private func loadCarousel(def: (id: String, title: String, subtitle: String?, source: CarouselSource), forceRefresh: Bool) async -> (String, [DiscoverBook], String?) {
        // Check cache first (unless forcing refresh)
        if !forceRefresh, let cached: [DiscoverBook] = await cache.cachedDecoded(forKey: def.id, as: [DiscoverBook].self) {
            return (def.id, cached, nil)
        }

        do {
            let books: [DiscoverBook]

            switch def.source {
            case .nytList(let listName):
                books = try await loadNYTList(named: listName, listID: def.id)

            case .openLibraryTrending:
                books = try await loadTrending()

            case .googleSearch(let query, let orderBy):
                books = try await loadGoogleSearch(query: query, orderBy: orderBy)
            }

            // Cache the results
            await cache.cacheEncodable(books, forKey: def.id)

            return (def.id, books, nil)
        } catch {
            print("[ForYouVM] Failed to load \(def.id): \(error)")
            // Return cached (even if stale) as fallback
            if let stale: [DiscoverBook] = await cache.cachedDecoded(forKey: def.id, as: [DiscoverBook].self) {
                return (def.id, stale, nil)
            }
            return (def.id, [], error.localizedDescription)
        }
    }

    // MARK: - NYT Loading

    private func loadNYTList(named listName: String, listID: String) async throws -> [DiscoverBook] {
        let nytBooks = try await nytService.fetchList(named: listName)

        // Convert to DiscoverBook and enrich with Google Books in parallel
        var discoverBooks = nytBooks.compactMap { nytBook -> DiscoverBook? in
            guard let title = nytBook.title else { return nil }
            return DiscoverBook(
                id: DiscoverBook.generateID(isbn13: nytBook.isbn13, olKey: nil, title: title, author: nytBook.author),
                title: title,
                subtitle: nil,
                authors: nytBook.author.map { [$0] } ?? [],
                coverURL: nytBook.bookImage.flatMap { URL(string: $0) },
                description: nytBook.description,
                publisher: nytBook.publisher,
                publishDate: nil,
                pageCount: nil,
                categories: nil,
                averageRating: nil,
                ratingsCount: nil,
                isbn13: nytBook.isbn13,
                isbn10: nytBook.isbn10,
                previewLink: nytBook.amazonProductURL,
                infoLink: nil,
                source: .nyt,
                listName: listName,
                rank: nytBook.rank
            )
        }

        // Enrich each book with Google Books data (fire-and-forget style, but we await)
        await withTaskGroup(of: Void.self) { group in
            for i in discoverBooks.indices {
                group.addTask {
                    await self.googleService.enrich(&discoverBooks[i], isbn: discoverBooks[i].isbn13)
                }
            }
            await group.waitForAll()
        }

        return discoverBooks
    }

    // MARK: - Open Library Trending

    private func loadTrending() async throws -> [DiscoverBook] {
        let works = try await olService.fetchTrending(limit: 20)
        var books = works.compactMap { olService.toDiscoverBook($0) }

        // Enrich with Google Books
        await withTaskGroup(of: Void.self) { group in
            for i in books.indices {
                group.addTask {
                    await self.googleService.enrich(&books[i], isbn: nil)
                }
            }
            await group.waitForAll()
        }

        return books
    }

    // MARK: - Google Books Search

    private func loadGoogleSearch(query: String, orderBy: String?) async throws -> [DiscoverBook] {
        let volumes = try await googleService.search(query: query, maxResults: 15, orderBy: orderBy)
        return volumes.compactMap { googleService.toDiscoverBook($0) }
    }
}
