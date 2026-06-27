//
//  BookDetailView.swift
//  MyApp
//
//  Created by Carlos Junior on 26/06/26.
//


//
//  BookDetailView.swift
//  MyApp
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(PlayerManager.self) var player
    @Environment(\.dismiss) var dismiss
    let book: VoxBook
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Cover Image
                if let data = book.coverData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 300)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .padding(.top, 40)
                } else {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 200, height: 300)
                        .cornerRadius(12)
                        .padding(.top, 40)
                }
                
                // Title and Author
                VStack(spacing: 8) {
                    Text(book.title)
                        .font(.title).bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    // Mark as finished logic here
                }) {
                    Text("Mark as Finished")
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                // Chapters List
                VStack(alignment: .leading, spacing: 0) {
                    Text("Chapters")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    if book.chapters.isEmpty {
                        Text("No chapters found. (Tap to start reading from beginning)")
                            .foregroundColor(.gray)
                            .padding()
                            .onTapGesture {
                                startReading(chapterIndex: 0)
                            }
                    } else {
                        ForEach(Array(book.chapters.enumerated()), id: \.offset) { index, chapter in
                            Button(action: {
                                startReading(chapterIndex: index)
                            }) {
                                HStack {
                                    Text(chapter.isEmpty ? "Chapter \(index + 1)" : chapter)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(Color(hex: "fa233b"))
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                            }
                            Divider().background(Color.gray.opacity(0.3))
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
        .background(
            LinearGradient(colors: [Color(hex: "4A6A55"), Color.black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        // This sheet modifier ensures ReaderView opens on top of this detail view
        .sheet(isPresented: Bindable(player).isFullReaderPresented) {
            if let activeBook = player.activeBook {
                ReaderView(book: activeBook).environment(player)
            }
        }
    }
    
    private func startReading(chapterIndex: Int) {
        player.activeBook = book
        book.currentChapterIdx = chapterIndex
        player.loadChapter(index: chapterIndex)
        player.isFullReaderPresented = true
    }
}