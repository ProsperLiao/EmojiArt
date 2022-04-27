//
//  ImageSaver.swift
//  EmojiArt
//
//  Created by Hongxing Liao on 2022/4/28.
//

import Foundation
import UIKit

class ImageSaver: NSObject {
    static let shared = ImageSaver()
    
    var completeHandler: ((Error?) -> Void)?
    
    private override init() { }
    
    func writeToPhotoAlbum(image: UIImage, completeHandler: @escaping (Error?) -> Void) {
        self.completeHandler = completeHandler
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc
    func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completeHandler?(error)
    }
}
