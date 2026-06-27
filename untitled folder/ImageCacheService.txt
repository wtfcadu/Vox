//
//  ImageCacheService.swift
//  VoxLibrary
//

import UIKit
import CryptoKit

/// Two-tier image cache: NSCache (fast, memory) + FileManager (persistent, disk).
/// Thread-safe via actor isolation.
actor ImageCacheService {
    static let shared = ImageCacheService()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    
    private init() {
        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
        
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDir.appendingPathComponent("BookCovers", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    /// Retrieve an image from cache (memory then disk).
    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        
        // Memory
        if let cached = memoryCache.object(forKey: key) { return cached }
        
        // Disk
        let diskKey = diskKey(for: url)
        let diskURL = diskCacheURL.appendingPathComponent(diskKey)
        if let data = try? Data(contentsOf: diskURL), let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        return nil
    }
    
    /// Store an image in both caches.
    func setImage(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        memoryCache.setObject(image, forKey: key)
        
        let diskURL = diskCacheURL.appendingPathComponent(diskKey(for: url))
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: diskURL, options: .atomic)
        }
    }
    
    /// Remove all cached images.
    func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    /// Generate a stable filename for a URL.
    private func diskKey(for url: URL) -> String {
        let string = url.absoluteString
        if let data = string.data(using: .utf8) {
            let hash = SHA256.hash(data: data)
            return hash.map { String(format: "%02x", $0) }.joined()
        }
        return string.hashValue.description
    }
}
