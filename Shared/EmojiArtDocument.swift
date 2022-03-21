//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/3/1.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            scheduleAutoSave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    @Published private(set) var backgroundImage: UIImage?
    @Published private(set) var backgroundImageFetchingStatus = BackgroundImageFetchingStatus.idle
    
    enum BackgroundImageFetchingStatus: Equatable {
        case idle
        case fetching
        case fail(URL)
    }
    
    var background: EmojiArtModel.Background { emojiArt.background }
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    
    init() {
        if let url = AutoSave.url, let autosavedEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autosavedEmojiArt
            fetchBackgroundImageDataIfNecessary()
             
        } else {
            emojiArt = EmojiArtModel()
            // emojiArt.addEmoji("😎", at: (-200, -100), size: 40)
            // emojiArt.addEmoji("😎", at: (0, 0), size: 40)
            // emojiArt.addEmoji("🥶", at: (100, 50), size: 20)
        }
    }
    
    private struct AutoSave {
        static let filename = "Autosaved.emojiart"
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0
    }
    
    private func autoSave() {
        if let url = AutoSave.url {
            save(to: url)
        }
    }
    
    private var autosaveTimer: Timer?
    
    private func scheduleAutoSave() {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: AutoSave.coalescingInterval, repeats: false) {_ in
            self.autoSave()
        }
    }
    
    private func save(to url: URL) {
        let thisFunction = "\(String(describing: self)).\(#function)"
        do {
            let data = try emojiArt.json()
            print("\(thisFunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
            print("\(thisFunction) success!")
        } catch let encodingError where encodingError is EncodingError {
            print("\(thisFunction) couldn't encode EmojiArt as JSON because \(encodingError.localizedDescription)")
        } catch {
            print("\(thisFunction) fail. error = \(error.localizedDescription)")
        }
    }
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background {
        case .url(let url):
            backgroundImageFetchingStatus = .fetching
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let imageData = try? Data(contentsOf: url)
                DispatchQueue.main.async { [weak self] in
                    if self?.emojiArt.background == EmojiArtModel.Background.url(url) {
                        self?.backgroundImageFetchingStatus = .idle
                        if imageData != nil  {
                            self?.backgroundImage = UIImage(data: imageData!)
                        }
                        if self?.backgroundImage == nil {
                            self?.backgroundImageFetchingStatus = .fail(url)
                        }
                    }
                }
            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        default:
            break
        }
    }
    
    // MARK: - Intent(s)
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func removeEmoji(_ emoji: EmojiArtModel.Emoji) {
        emojiArt.removeEmoji(emoji)
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}
