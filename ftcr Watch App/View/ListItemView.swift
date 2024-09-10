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
                HStack{
                    if let imageData = imageModel.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 37.5, height: 37.5)  // Set 1:1 aspect ratio
                            .clipShape(RoundedRectangle(cornerRadius: 2.5)) // Add rounded corners
                            .clipped()
                    } 
                    VStack(alignment: .leading) {
                        Text(imageModel.fileName)
                        Text(imageModel.fileSize)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    .truncationMode(.tail)
                }
                .transition(.blurReplace) // Apply
                .animation(.easeInOut, value: downloadViewModel.isDownloading)
            }
        }
        .onAppear {
            downloadVMDict.updateValue(downloadViewModel, forKey: imageModel.id)
        }
        }
    }

                                   
