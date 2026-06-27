//
//  MiniPlayerView.swift
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

// FIX: Removed the unused `CornerType` typealias that was declared here
// (public typealias CornerType = UIRectCorner / CACornerMask).
// It was never referenced in this file and belongs in RoundedCorner.swift if needed.

@available(iOS 17, *)
struct MiniPlayerView: View {
    @Environment(PlayerManager.self) var player

    var body: some View {
        HStack {
#if canImport(UIKit)
            if let book = player.activeBook, let data = book.coverData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().frame(width: 44, height: 44).cornerRadius(6)
            } else {
                Rectangle().fill(Color.gray).frame(width: 44, height: 44).cornerRadius(6)
            }
#else
            Rectangle().fill(Color.gray).frame(width: 44, height: 44).cornerRadius(6)
#endif

            VStack(alignment: .leading) {
                Text(player.activeBook?.title ?? "No Book").font(.subheadline).bold().foregroundColor(.white)
                Text(player.isPlaying ? "Now Playing" : "Paused").font(.caption2).foregroundColor(Color(hex: "fa233b")).bold()
            }
            Spacer()

            Button(action: { player.togglePlayPause() }) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
        .padding(10)
        .background(Color(white: 0.15).opacity(0.95))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
        .onTapGesture {
            player.isFullReaderPresented = true
        }
    }
}
