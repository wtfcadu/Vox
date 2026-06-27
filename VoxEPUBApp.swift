//
//  VoxEPUBApp.swift
//  VoxLibrary
//

import SwiftUI
import SwiftData

@main
struct VoxEPUBApp: App {
    @State private var playerManager = PlayerManager()

    private var isMiniPlayerVisible: Bool {
        playerManager.activeBook != nil && !playerManager.isFullReaderPresented
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                TabView {
                    // ── Tab 1: For You (NEW) ──
                    NavigationStack {
                        ForYouView()
                    }
                    .tabItem {
                        Label("For You", systemImage: "sparkles")
                    }

                    // ── Tab 2: Library (existing) ──
                    NavigationStack {
                        LibraryView()
                    }
                    .tabItem {
                        Label("Library", systemImage: "books.vertical")
                    }
                }
                .tint(Color(hex: "fa233b"))
                .environment(playerManager)

                // ── Mini Player (above tabs) ──
                if isMiniPlayerVisible {
                    MiniPlayerView()
                        .environment(playerManager)
                        .padding(.horizontal)
                        .padding(.bottom, 6) // sits just above the tab bar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: isMiniPlayerVisible)
            .preferredColorScheme(.dark)
            .tint(Color(hex: "fa233b"))
        }
        .modelContainer(for: VoxBook.self)
    }
}
