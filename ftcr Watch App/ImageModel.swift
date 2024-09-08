//
//  Image.swift
//  ftcr
//
//  Created by Jian Qin on 2024/8/28.
//

import SwiftData
import Foundation

/// SwiftData Model of downloaded images
///
@Model
class ImageModel: Identifiable, ObservableObject {
    var id: UUID = UUID()
    var url: URL
    var imageData: Data?
    var addedTime: Date = Date.now
    var fileName: String
    
    /// Initialzing the model by  downloading image data from `url` to `imageData`.
    /// - Parameter urlString: The url of the image provided when calling the initializer.
    init(url: URL) async {
        self.url = url
        self.fileName = url.lastPathComponent
        print("ImageModel initializing")
        let downloadViewModel: DownloadViewModel = DownloadViewModel()
        downloadVMDict.updateValue(downloadViewModel, forKey: self.id)
        await downloadViewModel.downloadImage(from: url) { data in
            if let data = data {
                self.imageData = data
            } else {
                print("Failed to download image data from \(url)")
            }
        }
    }
    
    
    /// Download the image data again after initializing.
    func reloadImageData() async {
        let downloadViewModel: DownloadViewModel = downloadVMDict[self.id] ?? DownloadViewModel()
        
        if downloadViewModel.isDownloading { return }
        await downloadViewModel.downloadImage(from: url) { data in
            if let data = data {
                self.imageData = data
            } else {
                print("Failed to download image data from \(self.url)")
            }
        }
    }
}
