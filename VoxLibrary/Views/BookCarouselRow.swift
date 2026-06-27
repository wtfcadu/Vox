//
//  BookCarouselRow.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  BookCarouselRow.swift
//  VoxLibrary
//

import SwiftUI

struct BookCarouselRow: View {
    let section: CarouselSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title)
                        .font(.title3)
                        .bold()

                    if let subtitle = section.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Optional: "See All" could navigate to a full list
                // For now, it's decorative
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)

            // Horizontal Scroll
            if section.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<6, id: \.self) { _ in
                            SkeletonBookCard()
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else if let error = section.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(section.books) { book in
                            NavigationLink(destination: DiscoverBookDetailView(book: book)) {
                                DiscoverBookCard(book: book)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}