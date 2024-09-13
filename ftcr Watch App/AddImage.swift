//
//  Downloader.swift
//  ftcr Watch App
//
//  Created by Jian Qin on 2024/8/28.
//
import Foundation
import SwiftData


@MainActor
func addImage(urlString: String, to modelContext: ModelContext) async throws {
    print("Attempting to add image(s) from URL: \(urlString)")
    
    var urlWithScheme = urlString
    
    // If the input doesn't start with "http://" or "https://", add "http://"
    if !urlWithScheme.lowercased().hasPrefix("http://") && !urlWithScheme.lowercased().hasPrefix("https://") {
        urlWithScheme = "http://\(urlWithScheme)"
    }
    
    // Updated regex for IPv4 LAN addresses allowing ports and paths
    let ipv4Regex = #"^(http://|https://)?(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.\d{1,3}\.\d{1,3})(:\d{1,5})?(/[^\s]*)?$"#
    let ipv6Regex = #"^(http://|https://)?\[(::1|(?:[fF]{0,4}:)?(?:[a-fA-F0-9]{1,4}:){1,7}[a-fA-F0-9]{1,4})\](?::\d{1,5})?(/[^\s]*)?$"#

    // Ensure the URL matches the IPv4 or IPv6 local area network formats
    if (urlWithScheme.range(of: ipv4Regex, options: .regularExpression) == nil) &&
        (urlWithScheme.range(of: ipv6Regex, options: .regularExpression) == nil) {
        print("Invalid or non-LAN IP address provided: \(urlWithScheme)")
        throw URLError(.badURL)
    }
    
    guard let validUrl = URL(string: urlWithScheme) else {
        print("Invalid URL provided: \(urlWithScheme)")
        throw URLError(.badURL)
    }
    
    print("Valid URL: \(validUrl)")
    let validExtensions = ["jpeg", "jpg", "png", "gif", "svg", "heic", "heics", "heif", "ico", "bmp", "cur", "tiff", "tif", "atx", "pbm"]
    
    // Check if the URL is an image or HTML page
    if validExtensions.contains(validUrl.pathExtension.lowercased()) {
        print("The URL points to an image file.")
        try await addSingleImage(url: validUrl, to: modelContext)
    } else {
        print("The URL points to an HTML page.")
        try await addImagesFromHTMLPage(url: validUrl, to: modelContext)
    }
}


@MainActor
private func addSingleImage(url: URL, to modelContext: ModelContext) async throws {
    do {
        print("Initializing new Image object for a single image")
        let newImage = await ImageModel(url: url)
        
        print("Inserting new Image object into context")
        modelContext.insert(newImage)
        
        print("Saving context...")
        
    }
}


@MainActor
private func addImagesFromHTMLPage(url: URL, to modelContext: ModelContext) async throws {
    do {
        let newImageList = ImageListModel(url: url)
        modelContext.insert(newImageList)
        
        print("Downloading HTML content from URL: \(url.absoluteString)")
        let html = try await downloadHTMLContent(from: url)
        
        print("Extracting image URLs from HTML content")
        let imageUrls = extractImageURLs(from: html, baseURL: url)
        
        for imageUrl in imageUrls {
            print("Initializing new Image object for image URL: \(imageUrl.absoluteString)")
            let newImage = await ImageModel(url: imageUrl, isChild: true)
            newImageList.images.append(newImage)
        }
        
    } catch {
        print("Failed to add images from HTML page: \(error.localizedDescription)")
        throw NSError(domain: "Error saving images from HTML page", code: 0, userInfo: nil)
    }
}


func downloadHTMLContent(from url: URL) async throws -> String {
    let request = URLRequest(url: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    
    if let httpResponse = response as? HTTPURLResponse {
        print("HTML download completed with status code: \(httpResponse.statusCode)")
    }
    
    guard let html = String(data: data, encoding: .utf8) else {
        throw NSError(domain: "Error converting data to string", code: 0, userInfo: nil)
    }
    
    return html
}


func extractImageURLs(from html: String, baseURL: URL) -> [URL] {
    var imageURLs: [URL] = []
    let pattern = "<a href=\"([^\"]+\\.(jpeg|jpg|png|gif|bmp|heic|heif|heics|ico|bmp|cur|pbm|atx|tif|tiff))\""
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let matches = regex?.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))
    
    matches?.forEach { match in
        if let range = Range(match.range(at: 1), in: html) {
            let relativePath = String(html[range])
            if let imageURL = URL(string: relativePath, relativeTo: baseURL) {
                imageURLs.append(imageURL)
            }
        }
    }
    return imageURLs
}


