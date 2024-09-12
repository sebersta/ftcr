import Foundation
import SwiftData

var viewModelDict: [UUID: DownloadViewModel] = [:]

class DownloadViewModel: NSObject, ObservableObject, URLSessionDataDelegate {
    @Published var isLoading = false
    @Published var speed: String = "0 KB/s"
    @Published var progress: Double = 0.0
    
    private var task: URLSessionDataTask?
    private var lastReceivedDataTime: Date?
    private var totalBytesReceived: Int64 = 0
    private var expectedContentLength: Int64 = 0
    private var receivedData = Data()
    private var completionHandler: ((Data?) -> Void)?
        
    func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) async {
        await MainActor.run {
            isLoading = true
            let startTime = Date()
            lastReceivedDataTime = startTime
            totalBytesReceived = 0
        }
        receivedData = Data()
        self.completionHandler = completion
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        task = session.dataTask(with: url)
        task?.resume()
    }
    
    // URLSessionDataDelegate methods to track progress
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.receivedData.append(data)
            let bytesReceived = Int64(data.count)
            self.totalBytesReceived += bytesReceived
            
            // Calculate progress
            if self.expectedContentLength > 0 {
                self.progress = Double(self.totalBytesReceived) / Double(self.expectedContentLength)
            }
            
            // Calculate speed
            let currentTime = Date()
            if let lastReceivedDataTime = self.lastReceivedDataTime {
                let timeInterval = currentTime.timeIntervalSince(lastReceivedDataTime)
                if timeInterval > 0.2 {
                    let speed = Double(bytesReceived) / 1024.0 / timeInterval
                    self.speed = String(format: "%.0f KB/s", speed)
                    self.lastReceivedDataTime = currentTime
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // Set expected content length
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            expectedContentLength = response.expectedContentLength
            totalBytesReceived = 0
            lastReceivedDataTime = Date()
        }
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                self.speed = "0 KB/s"
                self.completionHandler?(nil) // Return nil data on error
                return
            }
            
            self.completionHandler?(self.receivedData)
        }
    }
}
