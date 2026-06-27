//
//  DiscoverBookDetailViewModel.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  DiscoverBookDetailViewModel.swift
//  VoxLibrary
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DiscoverBookDetailViewModel {
    var book: DiscoverBook
    var downloadState: DownloadSheetState = .idle

    private let annaService = AnnaArchiveService()

    /// Check if this book is already in the user's library
    var isInLibrary: Bool = false

    init(book: DiscoverBook) {
        self.book = book
    }

    /// Check library for an existing copy. Call on appear.
    func checkLibrary(books: [VoxBook]) {
        let title = book.title.lowercased().trimmingCharacters(in: .whitespaces)
        let author = (book.authors.first ?? "").lowercased().trimmingCharacters(in: .whitespaces)

        isInLibrary = books.contains { libBook in
            libBook.title.lowercased().trimmingCharacters(in: .whitespaces) == title &&
            libBook.author.lowercased().trimmingCharacters(in: .whitespaces) == author
        }
    }

    // MARK: - Anna's Archive Search

    func searchAnnaArchive() async {
        downloadState = .searching

        // Build search query: title + first author
        let author = book.authors.first ?? ""
        let query = "\(book.title) \(author)"

        do {
            let results = try await annaService.search(query: query)
            downloadState = .results(results)
        } catch {
            downloadState = .error(error.localizedDescription)
        }
    }

    // MARK: - Get Mirrors

    func fetchMirrors(for result: AnnaSearchResult) async {
        downloadState = .fetchingMirrors(result: result)

        do {
            let mirrors = try await annaService.getMirrorLinks(detailPath: result.detailURL)

            if mirrors.isEmpty {
                downloadState = .error("No download links found for this entry.")
                return
            }

            // Pick the best mirror (prefer Internet Archive, then first available)
            let preferred = mirrors.first { $0.label.contains("Internet Archive") } ?? mirrors.first!

            // Start download
            await downloadFrom(mirror: preferred, result: result)
        } catch {
            downloadState = .error(error.localizedDescription)
        }
    }

    // MARK: - Download

    func downloadFrom(mirror: AnnaMirrorLink, result: AnnaSearchResult) async {
        downloadState = .downloading(progress: 0, result: result)

        do {
            let localURL = try await annaService.downloadFile(from: mirror.url) { progress in
                Task { @MainActor in
                    self.downloadState = .downloading(progress: progress, result: result)
                }
            }

            downloadState = .completed(localURL: localURL)
        } catch {
            downloadState = .error(error.localizedDescription)
        }
    }

    // MARK: - Import to Library

    func importDownloadedFile(url: URL, context: ModelContext) -> Bool {
        // Verify it's an EPUB
        let ext = url.pathExtension.lowercased()
        guard ext == "epub" else {
            print("[DownloadVM] Downloaded file is not EPUB: \(ext)")
            return false
        }

        let imported = EPUBImportService.importIntoContext(url, context: context)
        if imported != nil {
            isInLibrary = true
            // Clean up the downloaded temp file
            try? FileManager.default.removeItem(at: url)
        }
        return imported != nil
    }

    // MARK: - Safari Fallback

    /// Open Anna's Archive search in Safari when automatic search fails
    func openInSafari() {
        let author = book.authors.first ?? ""
        let query = "\(book.title) \(author)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "\(APIConfig.annaArchiveBase)/search?q=\(query)&ext=epub") {
            UIApplication.shared.open(url)
        }
    }

    /// Reset download state (dismiss sheet)
    func resetDownloadState() {
        downloadState = .idle
    }
}