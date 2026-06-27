//
//  APIConfig.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  APIConfig.swift
//  VoxLibrary
//

import Foundation

enum APIConfig {
    /// Get your free key at https://developer.nytimes.com/get-started
    /// Set this to your actual key. If nil, NYT carousels are skipped gracefully.
    static let nytApiKey: String? = "BEX5SLziBC2cLzqX3M5Bl0ly00x5n1eNM7Uc8y6fE7yxA0Td"
    
    static let googleBooksBase = "https://www.googleapis.com/books/v1"
    static let nytBooksBase = "https://api.nytimes.com/svc/books/v3"
    static let openLibraryBase = "https://openlibrary.org"
    static let annaArchiveBase = "https://annas-archive.gd"
    
    /// How long cached recommendations stay fresh (seconds)
    static let cacheTTL: TimeInterval = 3600 // 1 hour
}
