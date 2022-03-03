//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Hongxing Liao on 2022/2/28.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
