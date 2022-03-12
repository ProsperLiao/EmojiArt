//
//  ContentView.swift
//  Shared
//
//  Created by Hongxing Liao on 2022/2/28.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: (document: CGFloat, selectedEmojis: CGFloat) = (1, 1)
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale.document
    }
    
    @State private var steadyStatePanOffset: CGSize = CGSize(width: 0, height: 0)
    @GestureState private var gesturePanOffset: (document: CGSize, selectedEmojis: CGSize) =  (CGSize(width: 0, height: 0), CGSize(width: 0, height: 0))
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset.document) * zoomScale
    }
    
    @State private var selectedEmojis = Set<EmojiArtModel.Emoji>()
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                )
                    .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: singleTap()))
                if document.backgroundImageFetchingStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .border(selectedEmojis.index(matching: emoji) != nil ? Color.red : Color.clear)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                            .gesture(singleTap(emoji).simultaneously(with: emojiDragGesture(emoji)))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
        }
    }
    
    var palette: some View {
        ScrollingEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "😀😅😒😏😫😣☹️🙁😡🤬🥵🥶😱😨😴"
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        var fontSize = CGFloat(emoji.size)
        if let _ = selectedEmojis.index(matching: emoji) {
            fontSize = (CGFloat(emoji.size) * gestureZoomScale.selectedEmojis).rounded(.toNearestOrAwayFromZero)
        }
        return fontSize
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        var location = convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
        if let _ = selectedEmojis.index(matching: emoji) {
            location = convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry) + gesturePanOffset.selectedEmojis * zoomScale
        }
        return location
        
    }
    
    // emoji 坐标系原点在画图区的中点，需把emoji坐标系的位置转换为系统的坐标系的位置
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    // 把系统坐标系的点转换为 emoji 坐标系的位置
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
        
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { text in
                if let emoji = text.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        
        return found
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { scale, gestureZoomScale, _ in
                if selectedEmojis.isEmpty {
                    gestureZoomScale.document = scale
                } else {
                    gestureZoomScale.selectedEmojis = scale
                }
            }
            .onEnded { gestureScaleAtEnd in
                if selectedEmojis.isEmpty {
                    steadyStateZoomScale *= gestureScaleAtEnd
                } else {
                    for emoji in selectedEmojis {
                        document.scaleEmoji(emoji, by: gestureScaleAtEnd)
                    }
                }
            }
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset, body: { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset.document = latestDragGestureValue.translation / zoomScale
            })
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)

            }
    }
    
    private func emojiDragGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset, body: { latestDragGestureValue, gesturePanOffset, _ in
                if let _ = selectedEmojis.index(matching: emoji) {
                    gesturePanOffset.selectedEmojis = latestDragGestureValue.translation / zoomScale
                } else {
                    gesturePanOffset.document = latestDragGestureValue.translation / zoomScale
                }
            })
            .onEnded { finalDragGestureValue in
                if let _ = selectedEmojis.index(matching: emoji) {
                    for emoji in selectedEmojis {
                        document.moveEmoji(emoji, by: (finalDragGestureValue.translation / zoomScale))
                    }
                } else {
                    steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
                }
            }
    }
    
    private func singleTap(_ emoji: EmojiArtModel.Emoji? = nil) -> some Gesture {
        TapGesture()
            .onEnded {
                if let emoji = emoji {
                    selectedEmojis.toggleMembership(of: emoji)
                } else {
                    selectedEmojis = []
                }
            }
    }
    
//    struct Constants {
//        static let defaultFontSize: CGFloat = 20
//    }
}

struct ScrollingEmojisView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag {
                            NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
