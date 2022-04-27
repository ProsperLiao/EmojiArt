//
//  View+UIImage.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/4/26.
//

import SwiftUI

extension View {
    func asUIImage(size: CGSize) -> UIImage {
        var uiImage = UIImage(systemName: "exclamationmark.triangle.fill")!
        let controller = UIHostingController(rootView: self.edgesIgnoringSafeArea(.all))
        
        if let view = controller.view {
            view.bounds = CGRect(origin: .zero, size: size)
            uiImage = view.asImage()
        }
        
        return uiImage
    }
}

extension UIView {
    func asImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: self.layer.frame.size, format: format)
        return renderer.image { _ in
            self.drawHierarchy(in: self.layer.bounds, afterScreenUpdates: true)
        }
    }
}
