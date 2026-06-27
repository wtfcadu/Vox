//
//  CachedAsyncImage.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  CachedAsyncImage.swift
//  VoxLibrary
//

import SwiftUI
import UIKit

// MARK: - Cached Async Image

struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: Placeholder
    let contentMode: ContentMode

    @State private var image: UIImage?
    @State private var didAttemptLoad = false

    init(url: URL?, @ViewBuilder placeholder: () -> Placeholder, contentMode: ContentMode = .fill) {
        self.url = url
        self.placeholder = placeholder()
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if !didAttemptLoad {
                placeholder
                    .onAppear { load() }
            } else {
                placeholder // stays visible if load fails
            }
        }
    }

    private func load() {
        guard let url = url else { return }
        didAttemptLoad = true

        // 1. Ensure the UI updates happen on the Main Actor
        Task { @MainActor in
            // Check cache
            if let cached = await ImageCacheService.shared.image(for: url) {
                self.image = cached
                return
            }

            // Fetch from network
            do {
                // 2. Add a User-Agent so Google Books doesn't block the request
                var request = URLRequest(url: url)
                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
                
                let (data, _) = try await URLSession.shared.data(for: request)
                if let uiImage = UIImage(data: data) {
                    await ImageCacheService.shared.setImage(uiImage, for: url)
                    self.image = uiImage // Safely triggers UI redraw on main thread
                }
            } catch {
                print("[CachedAsyncImage] Failed to load URL: \(url.absoluteString) - Error: \(error)")
            }
        }
    }
}

// Convenience initializer with default book placeholder
extension CachedAsyncImage where Placeholder == SkeletonBookCard {
    init(url: URL?, width: CGFloat = 120, height: CGFloat = 180) {
        self.url = url
        self.placeholder = SkeletonBookCard(width: width, height: height)
        self.contentMode = .fill
    }
}

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.15),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width + phase * geo.size.width * 1.6)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Book Card

struct SkeletonBookCard: View {
    let width: CGFloat
    let height: CGFloat

    init(width: CGFloat = 120, height: CGFloat = 180) {
        self.width = width
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .frame(width: width, height: height)
                .shimmering()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
                .frame(width: width * 0.85, height: 14)
                .shimmering()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.05))
                .frame(width: width * 0.6, height: 12)
                .shimmering()
        }
    }
}
