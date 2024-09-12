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
        NavigationStack {
            List(images) { image in
                let viewModel = viewModelDict[image.id] ?? DownloadViewModel()
                
                NavigationLink(destination: ImageView(imageModel: image)) {
                    ListItemView(imageModel: image, downloadViewModel: viewModel)
                }
                .swipeActions(edge: .leading) {
                    Button() {
                        Task {
                            await reloadImage(image)
                        }
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteImage(image)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(viewModel.isLoading)
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
//                    Button {
//                        Task {
//                            do {
//    //                            try await addImage(urlString: "https://cdn.sebersta.com/copenhagen.jpg", to: modelContext)
//                                try await addImage(urlString: "http://192.168.40.155:8000", to: modelContext)
//                            } catch {
//                            }
//                        }
//                    } label : {
//                        Label("Show Menu",
//                        systemImage: "arrow.down")
//                    }
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
        }
    }

    
    
    private func deleteImage(_ image: ImageModel) {
        modelContext.delete(image)
        viewModelDict.removeValue(forKey: image.id)
    }
    
    private func reloadImage(_ image: ImageModel) async {
        await image.reloadImageData()
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: ImageModel.self)
}
