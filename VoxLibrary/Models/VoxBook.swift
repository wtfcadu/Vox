//
//  VoxBook.swift
//  MyApp
//

import SwiftUI
import SwiftData

@Model
class VoxBook {
    var id: String
    var title: String
    var author: String
    @Attribute(.externalStorage) var coverData: Data?
    @Attribute(.externalStorage) var epubData: Data
    var status: String
    
    // New properties for EPUB structure
    var chapters: [String]
    var chapterFiles: [String]
    
    var currentChapterIdx: Int
    var currentParaIdx: Int
    
    init(id: String = UUID().uuidString, title: String, author: String, coverData: Data? = nil, epubData: Data, status: String = "reading", chapters: [String] = [], chapterFiles: [String] = []) {
        self.id = id
        self.title = title
        self.author = author
        self.coverData = coverData
        self.epubData = epubData
        self.status = status
        self.chapters = chapters
        self.chapterFiles = chapterFiles
        self.currentChapterIdx = 0
        self.currentParaIdx = 0
    }
}
