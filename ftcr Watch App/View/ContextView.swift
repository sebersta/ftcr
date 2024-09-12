//
//  overlayView.swift
//  ftcr
//
//  Created by Jian Qin on 2024/8/29.
//

import SwiftUI
import SwiftData

/// The View containing two controll buttons. Appears over ContentView when triggered.
struct ContextView: View { // Renamed to follow Swift naming conventions
    @Binding var showContext: Bool
    @Environment(\.modelContext) var modelContext
    @Query(sort: \ImageModel.addedTime, order: .reverse) var images: [ImageModel]
    @Query(sort: \ImageListModel.addedTime, order: .reverse) var imageLists: [ImageListModel]
    
    var appVersion: String {
            (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "n/a"
        }

    var appDisplayName: String {
            (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? "App Name Not Available"
        }
    
    var body: some View {
        VStack {
            Spacer(minLength: 55)
            Button() {
                    reloadAll()
            } label: {
                Label("Reload All", systemImage: "arrow.clockwise")
            }
            Button(role: .destructive) {
                deleteAll()
            } label: {
                Label("Delete All", systemImage: "trash")
            }
            Spacer(minLength: 10)
            Text("\(appDisplayName) \(appVersion)")
                .foregroundStyle(.secondary)
        }
    }
    
    private func reloadAll() {
        Task {
            showContext = false
            for image in images {
                await image.reloadImageData()
            }
        }
    }
    
    private func deleteAll() {
        for image in images {
            modelContext.delete(image)
        }
        for imageList in imageLists {
            modelContext.delete(imageList)
        }
        viewModelDict.removeAll()
        showContext = false
    }
}

#Preview {
    ContextView(showContext: .constant(true))
//        .task {
//            try? Tips.resetDatastore()
//            try? Tips.configure([
//                .displayFrequency(.immediate),
//                .datastoreLocation(.applicationDefault)
//            ])
//        }
}
