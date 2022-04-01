//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/2/28.
//

import Foundation

struct EmojiArtModel: Codable {
    var background = Background.blank
    var emojis = [Emoji]()
    
    private var uniqueEmojiId = 0
    
    init() { }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArtModel.self, from: json)
    }
    
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try EmojiArtModel(json: data)
    }
    
    func json() throws -> Data {
        try JSONEncoder().encode(self)
    }
    
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        for ch in text {
            assert(ch.isEmoji)
        }
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
    
    mutating func removeEmoji(_ emoji: Emoji) {
        if let index = emojis.index(matching: emoji) {
            emojis.remove(at: index)
        }
    }

    struct Emoji: Identifiable, Hashable, Codable {
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
