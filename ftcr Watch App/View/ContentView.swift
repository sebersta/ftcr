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
    @Query(sort: \ImageListModel.addedTime, order: .reverse) var imageLists: [ImageListModel]
    @State var showContext = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(imageLists) { imageList in
                    NavigationLink(destination: ImageListView(imageList: imageList)) {
                        VStack(alignment: .leading) {
                            Text(imageList.url.absoluteString)
                            Text("\(imageList.images.count) images")
                                .foregroundStyle(.secondary)
                        }
                        .lineLimit(1)
                        .truncationMode(.tail)
                    }
                    .swipeActions(edge: .leading) {
                        Button() {
                            Task {
                                await imageList.reloadImageData()
                            }
                        } label: {
                            Label("Reload", systemImage: "arrow.clockwise")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            modelContext.delete(imageList)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                ForEach(images.filter { !$0.isChild }) { image in
                    let viewModel = viewModelDict[image.id] ?? DownloadViewModel()
                    
                    NavigationLink(destination: ImageView(imageModel: image)) {
                        ListLabelView(imageModel: image, downloadViewModel: viewModel)
                    }
                    .swipeActions(edge: .leading) {
                        Button() {
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
                            modelContext.delete(image)
                            viewModelDict.removeValue(forKey: image.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
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
//                Button {
//                    Task {
//                        do {
//                            try await addImage(urlString: "https://cdn.sebersta.com/copenhagen.jpg", to: modelContext)
//                            try await addImage(urlString: "http://192.168.40.155:8000", to: modelContext)
//                        } catch {
//                        }
//                    }
//                } label : {
//                    Label("Show Menu",
//                    systemImage: "arrow.down")
//                }
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

#Preview {
    ContentView()
        .modelContainer(for: ImageModel.self)
}
