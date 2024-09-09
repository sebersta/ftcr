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
    
    var body: some View {
        VStack {
            Button {
                    reloadAll()
            } label: {
                Label("Reload All", systemImage: "arrow.clockwise")
            }
            .padding(.bottom, 20)
            
            Button(role: .destructive) {
                deleteAll()
            } label: {
                Label("Delete All", systemImage: "trash")
            }
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
        downloadVMDict.removeAll()
        showContext = false
    }
}

#Preview {
    ContextView(showContext: .constant(true))
}
