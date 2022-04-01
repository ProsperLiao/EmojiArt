//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/3/16.
//

import Foundation

struct Palette: Identifiable, Codable, Hashable {
    var name: String
    var emojis: String
    var id: Int
    
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

class PaletteStore: ObservableObject {
    let name: String
    
    @Published var palettes = [Palette]() {
        didSet {
            storeInUserDefaults()
        }
    }
    
    init(named name: String) {
        self.name = name
        restoreFromUserDafaults()
        if palettes.isEmpty {
            print("using built-in palletes")
            insertPalette(named: "Vehicles", emojis: "🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🛻🚚🚛🚜🦼🦽🛴🚲🛵🏍🛺🚨🚔🚍🚘🚖🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇✈️🛩🚀🛸🚁🛶🚤🛥🛳⛴🚢")
            insertPalette(named: "Sports", emojis: "⚽️🏀🏈⚾️🥎🎾🏐🏉🥏🎱🪀🏓🏸")
            insertPalette(named: "Music", emojis: "🎤🎹🥁🎷🎺🪗🎸🪕🎻")
            insertPalette(named: "Animals", emojis: "🐒🐔🐧🐦🐤🐣🐥🦆🦅🦉🦇🐺🐗🐴🦄🐝🐞🦀🦑🐠🐬🐳🐋🐅🐆🦓🦧🦣🐄🐂🦘🦒🐓🦢🐇")
            insertPalette(named: "Animal Faces", emojis: "🐶🐱🐭🐹🐰🦊🐻🐼🐻‍❄️🐨🐯🦁🐮🐷🐽🐸🐵🙈🙉🙊")
            insertPalette(named: "Flora", emojis: "🌵🌳🌴☘️🍀🪴🍄🌺🌸🌼🌻🌹🌷💐🌾🍁")
            insertPalette(named: "Weather", emojis: "☀️🌤⛅️🌥☁️🌦🌧⛈🌩🌨❄️☃️☔️🌬💨")
            insertPalette(named: "COVID", emojis: "💉🦠💊🩺😷🤧🤮🤢")
            insertPalette(named: "Faces", emojis: "😀😃😄😁😆😅😂🤣🥲☺️😊😇🙂🙃😉😌😍🥰😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🥸🤩🥳😏😒😞😔😟😕🙁☹️😣😖😫😩🥺😢😭😤😠😡🤬🤯😳🥵🥶😶‍🌫️😱😨😰😥😓🤗🤔🤭🤫🤥😶😐😑😬🙄😯😦😧😮😲🥱😴🤤😪😮‍💨😵😵‍💫🤐🥴")
        } else {
            print("successfully loaded form UserDefaults: \(palettes)")
        }
    }
    
    private var userDefaultsKey: String {
        return "PaletteStore:\(name)"
    }
    
    private func storeInUserDefaults(){
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
    }
    
    private func restoreFromUserDafaults() {
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey), let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData) {
            palettes = decodedPalettes
        }
    }
    
    // MARK: - Intent(s)
    func palette(at index: Int) -> Palette {
        let safeIndex = min(max(0, index), palettes.count - 1)
        return palettes[safeIndex]
    }
    
    @discardableResult
    func removePalette(at index: Int) -> Int {
        if palettes.count > 1, palettes.indices.contains(index) {
            palettes.remove(at: index)
        }
        return index % palettes.count
    }
    
    func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
        let uniqueId = (palettes.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        let palette = Palette(name: name, emojis: emojis ?? "", id: uniqueId)
        let safeIndex = min(palettes.count, max(0, index))
        palettes.insert(palette, at: safeIndex)
    }
}
