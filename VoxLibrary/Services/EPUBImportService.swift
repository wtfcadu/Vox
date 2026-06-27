//
//  EPUBImportService.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  EPUBImportService.swift
//  VoxLibrary
//
//  Extracted from LibraryView so both the file importer AND the
//  Anna's Archive download flow share identical EPUB parsing logic.
//

import Foundation
import SwiftData
import EPUBKit

enum EPUBImportService {
    /// Parse an EPUB file at the given URL and return the data needed to create a VoxBook.
    static func parse(at fileURL: URL) throws -> EPUBParseResult {
        // Ensure the file is accessible
        let shouldStopAccessing = fileURL.startAccessingSecurityScopedResource()
        defer { if shouldStopAccessing { fileURL.stopAccessingSecurityScopedResource() } }

        let document = EPUBDocument(url: fileURL)
        let bookTitle = document?.title ?? fileURL.deletingPathExtension().lastPathComponent
        let bookAuthor = document?.author ?? "Unknown Author"

        var coverData: Data? = nil
        if let coverURL = document?.cover {
            coverData = try? Data(contentsOf: coverURL)
        }

        var chapters: [String] = []
        var chapterFiles: [String] = []

        if let doc = document {
            // Recursively search the Table of Contents for chapter titles
            func findChapterTitle(for path: String, in toc: [EPUBTableOfContents]) -> String? {
                for item in toc {
                    if let itemPath = item.item?.components(separatedBy: "#").first, itemPath == path {
                        return item.label
                    }
                    if let found = findChapterTitle(for: path, in: item.subTable ?? []) {
                        return found
                    }
                }
                return nil
            }

            for spineItem in doc.spine.items {
                if let manifestItem = doc.manifest.items[spineItem.idref] {
                    let filePath = manifestItem.path
                    let chapterName = findChapterTitle(for: filePath, in: doc.tableOfContents.subTable ?? [])
                                      ?? "Chapter \(chapters.count + 1)"
                    chapters.append(chapterName)
                    chapterFiles.append(filePath)
                }
            }
        }

        let epubData = try Data(contentsOf: fileURL)

        return EPUBParseResult(
            title: bookTitle,
            author: bookAuthor,
            coverData: coverData,
            epubData: epubData,
            chapters: chapters,
            chapterFiles: chapterFiles
        )
    }

    /// Convenience: parse and insert directly into the SwiftData context.
    @discardableResult
    static func importIntoContext(_ fileURL: URL, context: ModelContext) -> VoxBook? {
        do {
            let result = try parse(at: fileURL)
            let book = VoxBook(
                title: result.title,
                author: result.author,
                coverData: result.coverData,
                epubData: result.epubData,
                chapters: result.chapters,
                chapterFiles: result.chapterFiles
            )
            context.insert(book)
            return book
        } catch {
            print("[EPUBImportService] Import failed: \(error)")
            return nil
        }
    }

    struct EPUBParseResult {
        let title: String
        let author: String
        let coverData: Data?
        let epubData: Data
        let chapters: [String]
        let chapterFiles: [String]
    }
}