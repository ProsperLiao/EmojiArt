//
//  ImageCropper.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/4/29.
//

import SwiftUI
import CropViewController

struct ImageCropper: UIViewControllerRepresentable {
    var image: UIImage
    var handleCroppedImage: (UIImage?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(handleCroppedImage: handleCroppedImage)
    }
    
    func makeUIViewController(context: Context) -> CropViewController {
        let cropVC = CropViewController(image: image)
        cropVC.delegate = context.coordinator
        return cropVC
    }
    
    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
        // nothing to do here
    }
    
    class Coordinator: NSObject, CropViewControllerDelegate {
        var handleCroppedImage: (UIImage?) -> Void
        
        init(handleCroppedImage: @escaping (UIImage?) -> Void) {
            self.handleCroppedImage = handleCroppedImage
        }
        
        func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
            // 'image' is the newly cropped version of the original image
            handleCroppedImage(image)
        }
        
    }
}
