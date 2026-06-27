//
//  ReaderView.swift
//  MyApp
//
//  Created by Carlos Junior on 26/06/26.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ReaderView: View {
    @Environment(PlayerManager.self) var player
    @Environment(\.dismiss) var dismiss
    let book: VoxBook

    var body: some View {
        @Bindable var player = player
        
        ZStack {
#if canImport(UIKit)
            if let data = book.coverData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .ignoresSafeArea()
                    .blur(radius: 60)
                    .overlay(Color.black.opacity(0.5))
            } else {
                Color.black.ignoresSafeArea()
            }
#else
            Color.black.ignoresSafeArea()
#endif

            VStack(spacing: 0) {
                // TOP BAR
                HStack {
                    Button(action: {
                        player.isFullReaderPresented = false
                        dismiss()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundColor(Color(hex: "fa233b"))
                            .padding(8)
                    }
                    
                    Spacer()
                    
                    // VOICE SELECTION MENU
                    Menu {
                        Picker("Select Voice", selection: $player.selectedVoice) {
                            Text("Brian (Premium Male)").tag("en-US-BrianNeural")
                            Text("Jenny (Premium Female)").tag("en-US-JennyNeural")
                            Text("Guy (Male)").tag("en-US-GuyNeural")
                            Text("Aria (Female)").tag("en-US-AriaNeural")
                            Text("Ryan (UK Male)").tag("en-GB-RyanNeural")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(Color(hex: "fa233b"))
                            .padding(8)
                    }
                }
                .padding()

                // MAIN CONTENT SCROLL
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(Array(player.currentParagraphs.enumerated()), id: \.offset) { index, text in
                                Text(text)
                                    .font(.system(size: 19))
                                    .lineSpacing(8)
                                    .foregroundColor(player.currentParaIdx == index ? .white : .gray)
                                    .fontWeight(player.currentParaIdx == index ? .bold : .regular)
                                    .padding(.leading, player.currentParaIdx == index ? 16 : 0)
                                    .overlay(
                                        Rectangle()
                                            .fill(Color(hex: "fa233b"))
                                            .frame(width: 3)
                                            .opacity(player.currentParaIdx == index ? 1 : 0),
                                        alignment: .leading
                                    )
                                    .id(index)
                                    .onTapGesture {
                                        player.playParagraph(at: index)
                                    }
                            }
                        }
                        .padding()
                        .padding(.bottom, 160)
                    }
                    .onChange(of: player.currentParaIdx) { _, newIdx in
                        withAnimation { proxy.scrollTo(newIdx, anchor: .center) }
                    }
                }
            } // <--- MAIN VSTACK CLOSES HERE NOW

            // BOTTOM CONTROL BAR
            VStack {
                Spacer()
                VStack(spacing: 18) {
                    ProgressView(value: Double(player.currentParaIdx), total: Double(max(1, player.currentParagraphs.count)))
                        .tint(Color(hex: "fa233b"))

                    HStack(spacing: 40) {
                        Button(action: { player.prevChapter() }) {
                            Image(systemName: "backward.end.fill").font(.title2).foregroundColor(.white)
                        }
                        Button(action: { player.togglePlayPause() }) {
                            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 64, height: 64)
                                .foregroundColor(.white)
                        }
                        Button(action: { player.nextChapter() }) {
                            Image(systemName: "forward.end.fill").font(.title2).foregroundColor(.white)
                        }
                    }
                    Text("Playing Paragraph \(player.currentParaIdx + 1)/\(max(1, player.currentParagraphs.count))")
                        .font(.caption)
                        .foregroundColor(Color(hex: "fa233b"))
                        .bold()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                .ignoresSafeArea(edges: .bottom)
            }
        } // <--- ZSTACK CLOSES HERE NOW
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            player.activeBook = book
            player.isFullReaderPresented = true
            if player.currentParagraphs.isEmpty {
                player.loadChapter(index: 0)
            }
        }
        .onChange(of: player.selectedVoice) { _, _ in
            if player.isPlaying {
                // Restart the current paragraph immediately with the newly selected voice
                player.playParagraph(at: player.currentParaIdx)
            }
        }
    }
}
