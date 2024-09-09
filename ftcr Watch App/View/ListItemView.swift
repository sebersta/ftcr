import SwiftUI

struct ListItemView: View {  // Ensure ListItemView conforms to 'View'
    @ObservedObject var imageModel: ImageModel
    @ObservedObject var downloadViewModel: DownloadViewModel

    
    var body: some View {
        ZStack {
            if downloadViewModel.isDownloading {
                VStack {
                    HStack {
                        Text("Downloading...")
                        Spacer(minLength: 0)
                        Text(downloadViewModel.downloadSpeed)
                    }
                    .font(.caption2)
                    ProgressView(value: downloadViewModel.downloadProgress)
                        .tint(.accent)
                }
                .transition(.blurReplace) // Apply transition
                .animation(.easeInOut, value: downloadViewModel.isDownloading)
            } else {
                Text(imageModel.fileName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.blurReplace) // Apply
                    .animation(.easeInOut, value: downloadViewModel.isDownloading)
            }
        }
        .onAppear {
            downloadVMDict.updateValue(downloadViewModel, forKey: imageModel.id)
        }
        }
    }

