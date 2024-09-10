//
//  ContentView.swift
//  ftcr Watch App
//
//  Created by Jian Qin on 2024/8/28.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \ImageModel.addedTime, order: .reverse) var images: [ImageModel]
    @State var showContext = false

    var body: some View {
            List(images) { image in
                    let downloadViewModel = downloadVMDict[image.id] ?? DownloadViewModel()

                    NavigationLink(destination: ImageView(imageModel: image)) {
                        ListItemView(imageModel: image, downloadViewModel: downloadViewModel)
                    }
                    .swipeActions(edge: .leading) {
                        Button() {
                            Task {
                                await reloadImage(image)
                            }
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                        }
                        .disabled(downloadViewModel.isDownloading)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteImage(image)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(downloadViewModel.isDownloading)
                    }
            }
//            .containerBackground(Color.accentColor.gradient, for: .navigation)
            .navigationTitle("Images")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        showContext = true
                    } label : {
                        Label("Show Menu",
                        systemImage: "ellipsis")
                    }
                    TextFieldLink(prompt: Text("URL of the image")) {
                        Label("Add", systemImage: "plus")
                            .foregroundStyle(.accent)
                    } onSubmit: { result in
                        Task {
                            do {
                                try await addImage(urlString: result, to: modelContext)
                            } catch {
                                // Handle the error, for example, by showing an alert
                                print("Failed to add image: \(error)")
                            }
                        }
                    }
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                }
            }
            
            .sheet(isPresented: $showContext){
                ContextView(showContext: $showContext)
            }
//            .onAppear(
//                perform: {
//                    Task {
//                        do {
//                            try await addImage(urlString: "https://cdn.sebersta.com/copenhagen.jpg", to: modelContext)
//                            try await addImage(urlString: "https://cdn.sebersta.com/stockholm.png", to: modelContext)
//                        } catch {
//                        }
//                    }
//                }
//            )
    }

    
    
    private func deleteImage(_ image: ImageModel) {
        modelContext.delete(image)
        downloadVMDict.removeValue(forKey: image.id)
    }
    
    private func reloadImage(_ image: ImageModel) async {
        await image.reloadImageData()
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: ImageModel.self)
}
