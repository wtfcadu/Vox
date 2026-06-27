//
//  LibraryView.swift
//  MyApp
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import EPUBKit // Make sure to add this import!

private extension UTType {
    static let epub = UTType(importedAs: "org.idpf.epub-container")
}

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query private var books: [VoxBook]
    
    @State private var searchText = ""
    @State private var isImporting = false
    @Environment(PlayerManager.self) var player
    
    var body: some View {
        @Bindable var player = player
        
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    Spacer()
                    Button(action: { isImporting = true }) {
                        Label("Add EPUB", systemImage: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(hex: "fa233b"))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("My Library").font(.title2).bold()
                        Image(systemName: "arrow.right").foregroundColor(Color(hex: "fa233b")).font(.caption)
                    }.padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(books) { book in
                                // FIX 1: Use NavigationLink to open BookDetailView so you can see the chapters
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    VStack(alignment: .leading) {
                                        // FIX 2: Show the cover image if it exists in the library view too
                                        if let coverData = book.coverData, let uiImage = UIImage(data: coverData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 140, height: 210)
                                                .clipped()
                                                .cornerRadius(8)
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 140, height: 210)
                                                .cornerRadius(8)
                                        }
                                        
                                        Text(book.title).font(.subheadline).bold().lineLimit(1).foregroundColor(.white)
                                    }
                                    .frame(width: 140)
                                }
                            }
                        }.padding(.horizontal)
                    }
                }
            }.padding(.top)
        }
        .navigationTitle("VoxLibrary")
        .searchable(text: $searchText, prompt: "Search all books...")
        // We can remove the fullScreenCover from here since BookDetailView handles opening ReaderView now
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.epub]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    if FileManager.default.fileExists(atPath: tempURL.path) {
                        try FileManager.default.removeItem(at: tempURL)
                    }
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    
                    let epubData = try Data(contentsOf: tempURL)
                    let document = EPUBDocument(url: tempURL)
                    
                    let bookTitle = document?.title ?? url.deletingPathExtension().lastPathComponent
                    let bookAuthor = document?.author ?? "Unknown Author"
                    
                    var coverData: Data? = nil
                    if let coverURL = document?.cover {
                        coverData = try? Data(contentsOf: coverURL)
                    }
                    
                    var chapters: [String] = []
                    var chapterFiles: [String] = []
                    
                    if let doc = document {
                        
                        // 1. Helper function to recursively search the Table of Contents
                        // 1. Helper function to recursively search the Table of Contents
                        func findChapterTitle(for path: String, in toc: [EPUBTableOfContents]) -> String? {
                            for item in toc {
                                // TOC items often have anchor links like "chapter1.html#section1"
                                // We strip the anchor to match the base file path
                                if let itemPath = item.item?.components(separatedBy: "#").first, itemPath == path {
                                    return item.label
                                }
                                
                                // FIX 1: Add `?? []` so Swift knows what to do if subTable is nil
                                if let found = findChapterTitle(for: path, in: item.subTable ?? []) {
                                    return found
                                }
                            }
                            return nil
                        }

                        // 2. Loop through the spine to get the files in reading order
                        for spineItem in doc.spine.items {
                            if let manifestItem = doc.manifest.items[spineItem.idref] {
                                let filePath = manifestItem.path
                                
                                // FIX 2: Replace the <#default value#> placeholder with an empty array `[]`
                                let chapterName = findChapterTitle(for: filePath, in: doc.tableOfContents.subTable ?? [])
                                                  ?? "Chapter \(chapters.count + 1)"
                                
                                chapters.append(chapterName)
                                chapterFiles.append(filePath)
                            }
                        }
                    }
                    
                    let newBook = VoxBook(
                        title: bookTitle,
                        author: bookAuthor,
                        coverData: coverData,
                        epubData: epubData,
                        chapters: chapters,
                        chapterFiles: chapterFiles
                    )
                    context.insert(newBook)
                    
                    try? FileManager.default.removeItem(at: tempURL)
                    
                } catch {
                    print("[LibraryView] Failed to process EPUB: \(error)")
                }
                
            case .failure(let error):
                print("[LibraryView] File import failed: \(error.localizedDescription)")
            }
        }
        
        
    }
}
