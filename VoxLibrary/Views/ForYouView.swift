//
//  ForYouView.swift
//  VOXepub
//
//  Created by Carlos Junior on 27/06/26.
//


//
//  ForYouView.swift
//  VoxLibrary
//

import SwiftUI

struct ForYouView: View {
    @State private var viewModel = ForYouViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                // Carousel Rows
                ForEach(viewModel.sections) { section in
                    BookCarouselRow(section: section)
                        .padding(.bottom, 8)
                }

                // Last-refreshed footer
                if let date = viewModel.lastRefreshed {
                    HStack {
                        Spacer()
                        Text("Updated \(date, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100) // extra bottom for mini player space
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("For You")
        .task {
            await viewModel.loadAllSections()
        }
        .refreshable {
            await viewModel.loadAllSections(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoadingInitial && viewModel.sections.allSatisfy({ $0.isLoading }) {
                ProgressView("Finding books for you...")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("For You")
                .font(.largeTitle)
                .bold()

            if let date = viewModel.lastRefreshed {
                Text("Personalized recommendations · \(date, format: .dateTime.month().day().hour().minute())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("Personalized recommendations")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}