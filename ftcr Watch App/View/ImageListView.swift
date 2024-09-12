//
//  ImageListView.swift
//  ftcr
//
//  Created by Jian Qin on 2024/9/12.
//

import SwiftUI
import SwiftData


struct ImageListView: View {
    @ObservedObject var imageList: ImageListModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(imageList.images) { image in
                    let viewModel = viewModelDict[image.id] ?? DownloadViewModel()
                    
                    NavigationLink(destination: ImageView(imageModel: image)) {
                        ListLabelView(imageModel: image, downloadViewModel: viewModel)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            Task {
                                await image.reloadImageData()
                            }
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            imageList.images.remove(at: imageList.images.firstIndex(of: image)!)
                            viewModelDict.removeValue(forKey: image.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
        }
        .navigationBarTitle(imageList.url.absoluteString)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Spacer()
                Button() {
                    Task {
                        await imageList.reloadImageData()
                    }
                } label: {
                    Label("Reload All", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}
