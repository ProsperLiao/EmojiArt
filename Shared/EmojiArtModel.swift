//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/2/28.
//

import Foundation
import SwiftUI

struct EmojiArtModel {
    var background = Background.blank
    var emojis = [Emoji]()
    
    private var uniqueEmojiId = 0
    
    init() { }
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        for ch in text {
            assert(ch.isEmoji)
        }
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }

    struct Emoji: Identifiable, Hashable {
        let text: String
        var x: Int   // offset from the center
        var y: Int   // offset from the center
        var size: Int
        let id: Int
        
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }
}
