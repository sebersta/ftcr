//
//  Downloader.swift
//  ftcr Watch App
//
//  Created by Jian Qin on 2024/8/28.
//
import Foundation
import SwiftData

/// Attempts to add an image or multiple images from a URL to the provided model context.
///
/// This function takes a URL string and checks if it starts with "http://" or "https://". If it doesn't, it automatically adds "https://" to the URL string.
/// It then validates the URL and checks whether the URL points to a single image file or an HTML page. If the URL points to an image file (based on its extension),
/// the function attempts to add the image to the model context. If the URL points to an HTML page, the function attempts to extract and add all images from that page to the model context.
///
/// - Parameters:
///   - urlString: The URL string pointing to the image or HTML page.
///   - modelContext: The context in which the image(s) should be added.
/// - Throws: An error if the URL is invalid, the download fails, or the image(s) cannot be added to the model context.
///
/// - Example:
/// ```swift
/// do {
///     try await addImage(urlString: "https://example.com/image.jpg", to: modelContext)
///     print("Image(s) added successfully.")
/// } catch {
///     print("Failed to add image(s): \(error)")
/// }
/// ```
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

/// Adds a single image from the specified URL to the provided model context.
///
/// This function initializes a new `ImageModel` object using the provided URL and inserts it into the model context.
/// After insertion, the function attempts to save the context. If any errors occur during the process, they are caught and rethrown as a general `NSError`.
///
/// - Parameters:
///   - url: The URL of the image to be added.
///   - modelContext: The context in which the new image should be inserted and saved.
/// - Throws: An error if the image cannot be added or the context fails to save the new image.
///
/// - Example:
/// ```swift
/// do {
///     try await addSingleImage(url: imageURL, to: modelContext)
///     print("Image added successfully.")
/// } catch {
///     print("Failed to add image: \(error)")
/// }
/// ```
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

/// Adds images extracted from an HTML page at the specified URL to the provided model context.
///
/// This function downloads the HTML content from the given URL, extracts all image URLs within the HTML,
/// and creates a new `ImageModel` object for each image URL. Each image object is then inserted into the model context.
/// Finally, the context is saved. If an error occurs at any point in the process, it is caught and rethrown as a general `NSError`.
///
/// - Parameters:
///   - url: The URL of the HTML page containing images to be extracted and added.
///   - modelContext: The context in which the extracted images should be inserted and saved.
/// - Throws: An error if the HTML content cannot be downloaded, images cannot be extracted, or the context fails to save the new images.
///
/// - Example:
/// ```swift
/// do {
///     try await addImagesFromHTMLPage(url: pageURL, to: modelContext)
///     print("Images added successfully.")
/// } catch {
///     print("Failed to add images: \(error)")
/// }
/// ```
@MainActor
private func addImagesFromHTMLPage(url: URL, to modelContext: ModelContext) async throws {
    do {
        print("Downloading HTML content from URL: \(url.absoluteString)")
        let html = try await downloadHTMLContent(from: url)
        
        print("Extracting image URLs from HTML content")
        let imageUrls = extractImageURLs(from: html, baseURL: url)
        
        for imageUrl in imageUrls {
            print("Initializing new Image object for image URL: \(imageUrl.absoluteString)")
            let newImage = await ImageModel(url: imageUrl)
            
            print("Inserting new Image object into context")
            modelContext.insert(newImage)
        }
        
    } catch {
        print("Failed to add images from HTML page: \(error.localizedDescription)")
        throw NSError(domain: "Error saving images from HTML page", code: 0, userInfo: nil)
    }
}

/// Downloads HTML content from the specified URL and returns it as a string.
///
/// This asynchronous function sends a request to the given URL and attempts to download the HTML content.
/// After successfully downloading the content, it converts the data to a UTF-8 encoded string.
/// If the conversion fails, an error is thrown.
///
/// - Parameter url: The URL from which to download the HTML content.
/// - Returns: The downloaded HTML content as a `String`.
/// - Throws: An error if the download fails, the response is invalid, or the data cannot be converted to a string.
///
/// - Example:
/// ```swift
/// do {
///     let htmlContent = try await downloadHTMLContent(from: pageURL)
///     print("Downloaded HTML content successfully.")
/// } catch {
///     print("Failed to download HTML content: \(error)")
/// }
/// ```
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

/// Extracts image URLs from the provided HTML content using a regular expression.
///
/// This function searches the given HTML string for anchor tags (`<a>`) that link to image files
/// with extensions such as `.jpeg`, `.jpg`, `.png`, and others. It converts relative paths to full URLs using the provided base URL.
/// The function returns an array of URLs pointing to the extracted images.
///
/// - Parameters:
///   - html: The HTML content as a `String` from which to extract image URLs.
///   - baseURL: The base URL used to resolve relative image paths into full URLs.
/// - Returns: An array of `URL` objects representing the image URLs found in the HTML content.
///
/// - Example:
/// ```swift
/// let htmlContent = "<a href=\"/images/photo.jpg\">Photo</a>"
/// let imageUrls = extractImageURLs(from: htmlContent, baseURL: baseURL)
/// imageUrls.forEach { print($0.absoluteString) }
/// ```
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


