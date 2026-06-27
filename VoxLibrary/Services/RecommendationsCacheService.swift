//
//  RecommendationsCacheService.swift
//  VoxLibrary
//

import Foundation

/// Caches JSON API responses to disk so recommendations load instantly on subsequent opens.
actor RecommendationsCacheService {
    static let shared = RecommendationsCacheService()

    private let cacheDir: URL

    private init() {
        let dirs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDir = dirs.first!.appendingPathComponent("RecommendationsCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Read
    // Update the read methods to be async:

    func cachedData(forKey key: String) async -> Data? {
        let fileURL = cacheDir.appendingPathComponent(sanitize(key))
        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        
        // Await the MainActor property here
        if let modDate = attrs?[.modificationDate] as? Date,
           Date().timeIntervalSince(modDate) < (await APIConfig.cacheTTL) {
            return try? Data(contentsOf: fileURL)
        }
        // Stale — remove it
        try? FileManager.default.removeItem(at: fileURL)
        return nil
    }

    func cachedDecoded<T: Decodable>(forKey key: String, as type: T.Type) async -> T? {
        // Await the call to cachedData
        guard let data = await cachedData(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Write

    func cacheData(_ data: Data, forKey key: String) {
        let fileURL = cacheDir.appendingPathComponent(sanitize(key))
        try? data.write(to: fileURL, options: .atomic)
    }

    func cacheEncodable<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            cacheData(data, forKey: key)
        }
    }

    // MARK: - Clear

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    /// Turn a cache key into a safe filename
    private func sanitize(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
         .replacingOccurrences(of: "?", with: "_")
         .replacingOccurrences(of: "&", with: "_")
         .replacingOccurrences(of: "=", with: "_")
    }
}
