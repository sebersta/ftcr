//
//  ImageListModel.swift
//  ftcr
//
//  Created by Jian Qin on 2024/9/12.
//

import SwiftData
import Foundation

@Model
class ImageListModel: ObservableObject, Identifiable {
    var id: UUID = UUID()
    @Attribute(.unique) var url: URL
    var addedTime: Date = Date.now
    
    @Relationship(deleteRule: .cascade)
    var images = [ImageModel]()
    
    init(url: URL) {
        self.url = url
    }
    
    func reloadImageData() async {
        do {
            
            let html = try await downloadHTMLContent(from: url)
            
            let imageUrls = extractImageURLs(from: html, baseURL: url)
            
            if !imageUrls.isEmpty {
                self.images.removeAll()
                for imageUrl in imageUrls {
                    let newImage = await ImageModel(url: imageUrl, isChild: true)
                    self.images.append(newImage)
                }
            }
            
        } catch {
            print("Failed to add images from HTML page: \(error.localizedDescription)")
        }
    }
}

