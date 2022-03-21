//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/3/18.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var palette: Palette
    @State private var emojisToAdd = ""
    
    var body: some View {
        Form {
            nameSection
            addEmojisSection
            removeEmojiSection
        }
        .navigationTitle("Edit \(palette.name)")
        .frame(minWidth: 300, minHeight: 350)
    }
    
    var nameSection: some View {
        Section {
            TextField("Name", text: $palette.name)
        } header: {
            Text("Name")
        }
    }
    
    var addEmojisSection: some View {
        Section {
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd) { emojis in
                    addEmojis(emojis)
                }
        } header: {
            Text("Add Emojis")
        }
    }
    
    var removeEmojiSection: some View {
        Section {
            let emojis = palette.emojis.withNoRepeatedCharacters.map {
                String($0)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji).onTapGesture {
                        withAnimation {
                            palette.emojis.removeAll { String($0) == emoji }
                        }
                    }
                }
            }
            .font(.system(size: 40))
        } header: {
            Text("Remove Emoji")
        }

    }
    
    private func addEmojis(_ emojis: String) {
        withAnimation {
            palette.emojis = (emojis + palette.emojis)
                .filter { $0.isEmoji }
                .withNoRepeatedCharacters
        }
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        let palette = PaletteStore(named: "Test").palette(at: 2)
        PaletteEditor(palette: .constant(palette))
            .previewLayout(.fixed(width: 300, height: 350))
        PaletteEditor(palette: .constant(palette))
            .previewLayout(.fixed(width: 300, height: 600))
    }
}
