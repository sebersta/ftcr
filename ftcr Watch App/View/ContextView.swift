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
    @Binding var showOverlay: Bool
    @Environment(\.modelContext) var modelContext
    @Query(sort: \ImageModel.addedTime, order: .reverse) var images: [ImageModel]
    
    var body: some View {
        ZStack {
            Color.black // Solid black background
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showOverlay = false
                    }
                }
            
            VStack {
                Button {
//                    reloadAll()
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
        .transition(.scale(scale: 1.2, anchor: .center).combined(with: .opacity))
//        .animation(.easeInOut(duration: 0.1), value: showOverlay)
    }
    
    private func reloadAll() {
        Task {
            withAnimation {
                showOverlay = false
            }
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
        withAnimation {
            showOverlay = false
        }
    }
}

#Preview {
    ContextView(showOverlay: .constant(true))
}
