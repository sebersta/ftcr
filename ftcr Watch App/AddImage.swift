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
        
    // If the input doesn't start with "http://" or "https://", add "https://"
    if !urlWithScheme.lowercased().hasPrefix("http://") && !urlWithScheme.lowercased().hasPrefix("https://") {
        urlWithScheme = "https://\(urlWithScheme)"
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


// Function to replace HTML entities with their actual characters
func decodeHTMLEntities(in content: String) -> String {
    var decodedContent = content
    let entities = [
        "&lt;": "<",
        "&gt;": ">",
        "&quot;": "\"",
        "&apos;": "'",
        "&amp;": "&"
    ]
    
    entities.forEach { key, value in
        decodedContent = decodedContent.replacingOccurrences(of: key, with: value)
    }
    
    return decodedContent
}

// Download HTML or XML content
func downloadHTMLContent(from url: URL) async throws -> String {
    let request = URLRequest(url: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    
    if let httpResponse = response as? HTTPURLResponse {
        print("Download completed with status code: \(httpResponse.statusCode)")
    }
    
    guard let content = String(data: data, encoding: .utf8) else {
        throw NSError(domain: "Error converting data to string", code: 0, userInfo: nil)
    }
    
    return content
}

// Extract image URLs from HTML or XML content
func extractImageURLs(from content: String, baseURL: URL) -> [URL] {
    var imageURLs: [URL] = []
    
    // Decode HTML entities before searching for image URLs
    let decodedContent = decodeHTMLEntities(in: content)
    
    // Pattern for image extensions in HTML <a> tags and <img> tags in RSS <description> fields
    let imagePattern = "<img src=\"([^\"]+\\.(jpeg|jpg|png|gif|bmp|heic|heif|ico|cur|pbm|tif|tiff))\""
    
    // Find URLs using the pattern
    let regex = try? NSRegularExpression(pattern: imagePattern, options: [])
    let matches = regex?.matches(in: decodedContent, options: [], range: NSRange(decodedContent.startIndex..., in: decodedContent))
    
    matches?.forEach { match in
        if let range = Range(match.range(at: 1), in: decodedContent) {
            let relativePath = String(decodedContent[range])
            if let imageURL = URL(string: relativePath, relativeTo: baseURL) {
                imageURLs.append(imageURL)
            }
        }
    }
    
    // Log results
    print("Found \(imageURLs.count) image URLs")
    
    return imageURLs
}
