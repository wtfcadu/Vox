//
//  DiscoverBookCard.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  DiscoverBookCard.swift
//  VoxLibrary
//

import SwiftUI

struct DiscoverBookCard: View {
    let book: DiscoverBook

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover Image
            CachedAsyncImage(
                url: book.coverURL,
                placeholder: { SkeletonBookCard(width: 120, height: 180) }
            )
            .frame(width: 120, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.2), radius: 6, y: 3)

            // Title
            Text(book.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundStyle(.primary)
                .frame(width: 120, alignment: .leading)

            // Author
            if let author = book.authors.first {
                Text(author)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 120, alignment: .leading)
            }

            // Rating (if available)
            if let rating = book.averageRating, rating > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 120)
    }
}