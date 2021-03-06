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
            insertPalette(named: "Vehicles", emojis: "๐๐๐๐๐๐๐๐๐๐๐ป๐๐๐๐ฆผ๐ฆฝ๐ด๐ฒ๐ต๐๐บ๐จ๐๐๐๐๐ก๐ ๐๐๐๐๐๐๐๐๐๐๐โ๏ธ๐ฉ๐๐ธ๐๐ถ๐ค๐ฅ๐ณโด๐ข")
            insertPalette(named: "Sports", emojis: "โฝ๏ธ๐๐โพ๏ธ๐ฅ๐พ๐๐๐ฅ๐ฑ๐ช๐๐ธ")
            insertPalette(named: "Music", emojis: "๐ค๐น๐ฅ๐ท๐บ๐ช๐ธ๐ช๐ป")
            insertPalette(named: "Animals", emojis: "๐๐๐ง๐ฆ๐ค๐ฃ๐ฅ๐ฆ๐ฆ๐ฆ๐ฆ๐บ๐๐ด๐ฆ๐๐๐ฆ๐ฆ๐ ๐ฌ๐ณ๐๐๐๐ฆ๐ฆง๐ฆฃ๐๐๐ฆ๐ฆ๐๐ฆข๐")
            insertPalette(named: "Animal Faces", emojis: "๐ถ๐ฑ๐ญ๐น๐ฐ๐ฆ๐ป๐ผ๐ปโโ๏ธ๐จ๐ฏ๐ฆ๐ฎ๐ท๐ฝ๐ธ๐ต๐๐๐")
            insertPalette(named: "Flora", emojis: "๐ต๐ณ๐ดโ๏ธ๐๐ชด๐๐บ๐ธ๐ผ๐ป๐น๐ท๐๐พ๐")
            insertPalette(named: "Weather", emojis: "โ๏ธ๐คโ๏ธ๐ฅโ๏ธ๐ฆ๐งโ๐ฉ๐จโ๏ธโ๏ธโ๏ธ๐ฌ๐จ")
            insertPalette(named: "COVID", emojis: "๐๐ฆ ๐๐ฉบ๐ท๐คง๐คฎ๐คข")
            insertPalette(named: "Faces", emojis: "๐๐๐๐๐๐๐๐คฃ๐ฅฒโบ๏ธ๐๐๐๐๐๐๐๐ฅฐ๐๐๐๐๐๐๐๐๐คช๐คจ๐ง๐ค๐๐ฅธ๐คฉ๐ฅณ๐๐๐๐๐๐๐โน๏ธ๐ฃ๐๐ซ๐ฉ๐ฅบ๐ข๐ญ๐ค๐ ๐ก๐คฌ๐คฏ๐ณ๐ฅต๐ฅถ๐ถโ๐ซ๏ธ๐ฑ๐จ๐ฐ๐ฅ๐๐ค๐ค๐คญ๐คซ๐คฅ๐ถ๐๐๐ฌ๐๐ฏ๐ฆ๐ง๐ฎ๐ฒ๐ฅฑ๐ด๐คค๐ช๐ฎโ๐จ๐ต๐ตโ๐ซ๐ค๐ฅด")
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
