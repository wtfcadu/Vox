//
//  DiscoverBookDetailView.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  DiscoverBookDetailView.swift
//  VoxLibrary
//

import SwiftUI
import SwiftData

struct DiscoverBookDetailView: View {
    let book: DiscoverBook

    @State private var viewModel: DiscoverBookDetailViewModel
    @State private var showDownloadSheet = false
    @Query private var libraryBooks: [VoxBook]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(book: DiscoverBook) {
        self.book = book
        self._viewModel = State(initialValue: DiscoverBookDetailViewModel(book: book))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Cover + Hero
                heroSection
                    .padding(.top, 20)

                // Metadata pills
                if let categories = book.categories, !categories.isEmpty {
                    categoryPills(categories)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }

                // Description
                if let description = book.description, !description.isEmpty {
                    descriptionSection(description)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                }

                // Details table
                detailsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                // Bottom spacer for button
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let infoLink = book.infoLink, let url = URL(string: infoLink) {
                    Link(destination: url) {
                        Image(systemName: "safari")
                    }
                }
            }
        }
        .onAppear {
            viewModel.checkLibrary(books: libraryBooks)
        }
        .onChange(of: libraryBooks.count) {
            viewModel.checkLibrary(books: libraryBooks)
        }
        .sheet(isPresented: $showDownloadSheet, onDismiss: {
            viewModel.resetDownloadState()
        }) {
            DownloadSheet(viewModel: viewModel, modelContext: modelContext)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .safeAreaInset(edge: .bottom) {
            actionButton
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Cover
            CachedAsyncImage(
                url: book.coverURL,
                placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 270)
                        .shimmering()
                }
            )
            .frame(width: 180, height: 270)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.25), radius: 15, y: 8)
            .padding(.top, 10)

            // Title
            Text(book.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Subtitle
            if let subtitle = book.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            // Authors
            Text(book.authors.joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 30)

            // Star Rating
            if let rating = book.averageRating, rating > 0 {
                HStack(spacing: 6) {
                    starView(rating: rating)
                    if let count = book.ratingsCount, count > 0 {
                        Text("\(count.formatted()) ratings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 4)
            }

            // Source badge
            HStack(spacing: 6) {
                Image(systemName: sourceIcon)
                    .font(.caption2)
                Text(sourceLabel)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
    }

    // MARK: - Star Rating View

    private func starView(rating: Double) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= Int(rating.rounded()) ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
            }
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private var sourceIcon: String {
        switch book.source {
        case .nyt: return "newspaper"
        case .googleBooks: return "magnifyingglass"
        case .openLibrary: return "book"
        }
    }

    private var sourceLabel: String {
        switch book.source {
        case .nyt:
            return book.listName.map { "NYT: \($0)" } ?? "New York Times"
        case .googleBooks:
            return "Google Books"
        case .openLibrary:
            return "Open Library"
        }
    }

    // MARK: - Category Pills

    private func categoryPills(_ categories: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(categories.prefix(5).enumerated()), id: \.offset) { _, cat in
                    Text(cat)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "fa233b").opacity(0.1))
                        .foregroundStyle(Color(hex: "fa233b"))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Description

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this book")
                .font(.headline)

            // Expandable description
            ExpandableText(text: description)
        }
    }

    // MARK: - Details Table

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Details")
                .font(.headline)
                .padding(.bottom, 12)

            if let publisher = book.publisher {
                detailRow(label: "Publisher", value: publisher)
            }
            if let date = book.publishDate {
                detailRow(label: "Published", value: date)
            }
            if let pages = book.pageCount {
                detailRow(label: "Pages", value: "\(pages)")
            }
            if let isbn = book.isbn13 {
                detailRow(label: "ISBN-13", value: isbn)
            }
            if let isbn = book.isbn10 {
                detailRow(label: "ISBN-10", value: isbn)
            }
            if let lang = book.categories?.first(where: { $0.lowercased().contains("language") }) {
                detailRow(label: "Language", value: lang)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .foregroundStyle(.primary)
            Spacer()
        }
        .font(.subheadline)
        .padding(.vertical, 6)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Group {
            if viewModel.isInLibrary {
                // Already in library
                Button {
                    dismiss()
                } label: {
                    Label("In Library", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Button {
                    showDownloadSheet = true
                } label: {
                    Label("Get Book", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "fa233b"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
}

// MARK: - Expandable Text

struct ExpandableText: View {
    let text: String
    @State private var isExpanded = false
    @State private var isTruncatable = false

    private let lineLimit = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(isExpanded ? nil : lineLimit)
                .background(
                    // Hidden text to detect truncation
                    Text(text)
                        .font(.subheadline)
                        .lineLimit(lineLimit)
                        .hidden()
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: TruncationKey.self, value: geo.size.height)
                        })
                )
                .onPreferenceChange(TruncationKey.self) { hiddenHeight in
                    // Compare with actual height
                }

            if !isExpanded {
                Button("Read more") {
                    withAnimation { isExpanded = true }
                }
                .font(.caption)
                .foregroundStyle(Color(hex: "fa233b"))
            }
        }
    }
}

private struct TruncationKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
