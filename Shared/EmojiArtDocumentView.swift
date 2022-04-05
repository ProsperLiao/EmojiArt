//
//  ContentView.swift
//  Shared
//
//  Created by Hongxing Liao on 2022/2/28.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Environment(\.undoManager) var undoManager
    
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: (document: CGFloat, selectedEmojis: CGFloat) = (1, 1)
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale.document
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = CGSize(width: 0, height: 0)
    @GestureState private var gesturePanOffset: (documentOffset: CGSize, selectedEmojisOffset: CGSize, unselectedMovingEmoji: (emoji: EmojiArtModel.Emoji, offset: CGSize)?) =  (CGSize(width: 0, height: 0), CGSize(width: 0, height: 0), nil)
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset.documentOffset) * zoomScale
    }
    
    @State private var selectedEmojis = Set<EmojiArtModel.Emoji>()
    
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    enum BackgroundPickerType: Identifiable {
        var id: BackgroundPickerType { self }
        
        case camera
        case library
    }
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: singleTap()))
                if document.backgroundImageFetchingStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .border(selectedEmojis.index(matching: emoji) != nil ? Color.red : Color.clear)
                            .animatableSystemFontModifier(size: (fontSize(for: emoji) * zoomScale).rounded(.toNearestOrAwayFromZero) )
                            .position(position(for: emoji, in: geometry))
                            .gesture(singleTap(emoji).simultaneously(with: emojiDragGesture(emoji)))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.utf8PlainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchingStatus) { status in
                switch status {
                case .fail(let url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                if autoZoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .compactableToolbar {
                #if os(iOS)
                if let undoManager = undoManager {
                    if undoManager.canUndo {
                        AnimatedActionButton(title: undoManager.undoMenuItemTitle, systemImage: "arrow.uturn.backward") {
                            undoManager.undo()
                        }
                    }
                    if undoManager.canRedo {
                        AnimatedActionButton(title: undoManager.redoMenuItemTitle, systemImage: "arrow.uturn.forward") {
                            undoManager.redo()
                        }
                    }
                }
                #endif
                
                if !selectedEmojis.isEmpty {
                    AnimatedActionButton(title: "Delete Selected", systemImage: "trash") {
                        for emoji in selectedEmojis {
                            document.removeEmoji(emoji, undoManager: undoManager)
                        }
                        selectedEmojis = []
                    }
                    .font(.system(size: 20))
                    .tint(.red)
                }
                
                AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                    pasteBackground()
                }
                
                if Camera.isAvailable {
                    AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                
                if PhotoLibrary.isAvailable {
                    AnimatedActionButton(title: "Search Photo", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
            }
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera { image in handlePickedBackgroundImage(image) }
                case .library: PhotoLibrary { image in handlePickedBackgroundImage(image) }
                }
            }
        }
    }
    
    @State var autoZoom = false
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed:" + url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)."),
                dismissButton: .default(Text("OK"))
            )
        })
    }
    
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
            location = convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry) + gesturePanOffset.selectedEmojisOffset * zoomScale
        } else if let unselectedMovingEmoji = gesturePanOffset.unselectedMovingEmoji, unselectedMovingEmoji.emoji == emoji {
            location = convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry) + unselectedMovingEmoji.offset * zoomScale
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
            autoZoom = true
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        #if os(iOS)
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autoZoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        #endif
        if !found {
            found = providers.loadObjects(ofType: String.self) { text in
                if let emoji = text.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale, undoManager: undoManager
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
                        document.scaleEmoji(emoji, by: gestureScaleAtEnd, undoManager: undoManager)
                    }
                }
            }
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset, body: { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset.documentOffset = latestDragGestureValue.translation / zoomScale
            })
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    private func emojiDragGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset, body: { latestDragGestureValue, gesturePanOffset, _ in
                if let _ = selectedEmojis.index(matching: emoji) {
                    gesturePanOffset.selectedEmojisOffset = latestDragGestureValue.translation / zoomScale
                } else {
                    gesturePanOffset.unselectedMovingEmoji = (emoji, latestDragGestureValue.translation / zoomScale)
                    DispatchQueue.main.async {
                        selectedEmojis = []
                    }
                }
            })
            .onEnded { finalDragGestureValue in
                if let _ = selectedEmojis.index(matching: emoji) {
                    for emoji in selectedEmojis {
                        document.moveEmoji(emoji, by: (finalDragGestureValue.translation / zoomScale), undoManager: undoManager)
                    }
                } else {
                    document.moveEmoji(emoji, by: (finalDragGestureValue.translation / zoomScale), undoManager: undoManager)
                    selectedEmojis = []
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
    
    private func pasteBackground() {
        if let imageData = PasteBoard.imageData {
            autoZoom = true
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        } else if let url = PasteBoard.imageURL {
            autoZoom = true
            document.setBackground(.url(url), undoManager: undoManager)
        } else {
            alertToShow = IdentifiableAlert(
                title: "Paste Background",
                message: "There is no image currently on the pasteboard"
            )
        }
    }
    
    private func handlePickedBackgroundImage(_ image: UIImage?) {
        if let data = image?.imageData {
            autoZoom = true
            document.setBackground(.imageData(data), undoManager: undoManager)
        }
        backgroundPicker = nil
    }
    
//    struct Constants {
//        static let defaultFontSize: CGFloat = 20
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
