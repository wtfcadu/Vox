//
//  AnnaSearchResult.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  AnnaArchiveModels.swift
//  VoxLibrary
//

import Foundation

struct AnnaSearchResult: Identifiable, Sendable {
    let id: String
    let title: String
    let author: String
    let format: String
    let fileSize: String
    let language: String?
    let publisher: String?
    let detailURL: String // Relative URL like /md5/ABC123
}

struct AnnaMirrorLink: Identifiable, Sendable {
    let id: String
    let label: String
    let url: String
}

/// States for the download sheet UI
enum DownloadSheetState: Sendable {
    case idle
    case searching
    case results([AnnaSearchResult])
    case fetchingMirrors(result: AnnaSearchResult)
    case downloading(progress: Double, result: AnnaSearchResult)
    case completed(localURL: URL)
    case error(String)
}