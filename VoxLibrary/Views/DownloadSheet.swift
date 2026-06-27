//
//  DownloadSheet.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  DownloadSheet.swift
//  VoxLibrary
//

import SwiftUI
import SwiftData

@available(iOS 17, *)
struct DownloadSheet: View {
    @Bindable var viewModel: DiscoverBookDetailViewModel
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                switch viewModel.downloadState {
                case .idle:
                    idleView

                case .searching:
                    searchingView

                case .results(let results):
                    resultsList(results)

                case .fetchingMirrors(let result):
                    fetchingMirrorsView(result: result)

                case .downloading(let progress, let result):
                    downloadingView(progress: progress, result: result)

                case .completed(let url):
                    completedView(url: url)

                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Download")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if case .idle = viewModel.downloadState {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .onAppear {
                if case .idle = viewModel.downloadState {
                    Task { await viewModel.searchAnnaArchive() }
                }
            }
        }
    }

    // MARK: - Idle (should not be visible long)

    private var idleView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Preparing search...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Searching

    private var searchingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching Anna's Archive...")
                .font(.headline)
            Text("\"\(viewModel.book.title)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding()
    }

    // MARK: - Results

    private func resultsList(_ results: [AnnaSearchResult]) -> some View {
        VStack(spacing: 0) {
            Text("Found \(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)

            if results.isEmpty {
                ContentUnavailableView(
                    "No EPUB results",
                    systemImage: "book.closed",
                    description: Text("Try a different search or use Safari.")
                )
            } else {
                List {
                    ForEach(results) { result in
                        Button {
                            Task { await viewModel.fetchMirrors(for: result) }
                        } label: {
                            resultRow(result)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func resultRow(_ result: AnnaSearchResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(result.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label(result.author, systemImage: "person")
                if !result.fileSize.isEmpty {
                    Label(result.fileSize, systemImage: "doc")
                }
                Label(result.format, systemImage: "book")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let lang = result.language {
                Text(lang)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "fa233b").opacity(0.1))
                    .foregroundStyle(Color(hex: "fa233b"))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Fetching Mirrors

    private func fetchingMirrorsView(result: AnnaSearchResult) -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Finding download link...")
                .font(.headline)
            Text(result.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Downloading

    private func downloadingView(progress: Double, result: AnnaSearchResult) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "fa233b"))

            Text("Downloading")
                .font(.headline)

            Text(result.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(Color(hex: "fa233b"))
                    .progressViewStyle(.linear)

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 40)

            Text("Please wait — download speeds vary by mirror")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }

    // MARK: - Completed

    private func completedView(url: URL) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Download Complete!")
                .font(.headline)

            Text("Tap below to add this book to your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Button {
                let success = viewModel.importDownloadedFile(url: url, context: modelContext)
                if success {
                    dismiss()
                }
            } label: {
                Label("Add to Library", systemImage: "books.vertical.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "fa233b"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 30)

            Button("Cancel") {
                // Clean up the downloaded file
                try? FileManager.default.removeItem(at: url)
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Retry button
            Button {
                Task { await viewModel.searchAnnaArchive() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "fa233b"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 30)

            // Safari fallback
            Button {
                viewModel.openInSafari()
                dismiss()
            } label: {
                Label("Open in Safari", systemImage: "safari")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Button("Dismiss") { dismiss() }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding()
    }
}
