//
//  DetailedView.swift
//  ftcr
//
//  Created by Jian Qin on 2024/8/28.
//

import SwiftUI

struct ImageView: View {
    @ObservedObject var imageModel: ImageModel
    @State private var scale: CGFloat = 1.0
    @State private var crownValue: Double = 0.0
    @State private var offset: CGSize = .zero
    @State private var initialOffset: CGSize = .zero
    @State private var isUIHidden: Bool = false
    @State private var isScaledToFit: Bool = false
    
    let dragLimit: CGFloat = 200.0
    
    var body: some View {
        if let imageData = imageModel.imageData, let uiImage = UIImage(data: imageData) {
            ImageDisplayView(
                uiImage: uiImage,
                scale: $scale,
                crownValue: $crownValue,
                offset: $offset,
                initialOffset: $initialOffset,
                dragLimit: dragLimit,
                isUIHidden: $isUIHidden,
                isScaledToFit: $isScaledToFit
            )
            .navigationBarBackButtonHidden(isUIHidden)
            ._statusBarHidden(isUIHidden)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if !isUIHidden {
                        Spacer()
                        ShareLink(
                            item: uiImage,
                            preview: SharePreview(
                                imageModel.fileName,
                                image: uiImage)
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        } else {
            Text("Image not available, check the URL and the file source.")
        }
    }
}

struct ImageDisplayView: View {
    var uiImage: UIImage
    @Binding var scale: CGFloat
    @Binding var crownValue: Double
    @Binding var offset: CGSize
    @Binding var initialOffset: CGSize
    let dragLimit: CGFloat
    @Binding var isUIHidden: Bool
    @Binding var isScaledToFit: Bool

    var body: some View {
        Image(uiImage: uiImage)
            .centerCropped(isScaledToFit: isScaledToFit)
            ._statusBarHidden()
            .scaleEffect(scale)
            .offset(offset)
            .ignoresSafeArea()
            .focusable()
            .digitalCrownRotation($crownValue, from: -5, through: 20, by: 0.2, sensitivity: .high, isContinuous: false, isHapticFeedbackEnabled: true)
            .onChange(of: crownValue, initial: false) { oldValue, newValue in
                scale = CGFloat(1 + newValue / 10)
                isUIHidden = true
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newWidth = initialOffset.width + value.translation.width
                        let newHeight = initialOffset.height + value.translation.height
                        
                        offset = CGSize(
                            width: max(min(newWidth, dragLimit), -dragLimit),
                            height: max(min(newHeight, dragLimit), -dragLimit)
                        )
                    }
                    .onEnded { value in
                        initialOffset = offset
                    }
            )
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        if scale != 1 || offset != .zero {
                            scale = 1
                            offset = .zero
                            crownValue = 0.0
                            isScaledToFit = true
                        } else {
                            crownValue = 0.0
                            isScaledToFit.toggle()
                        }
                    }
                .exclusively(before: TapGesture()
                    .onEnded {
                        isUIHidden.toggle()
                    })
            )
    }
}

extension Image {
    func centerCropped(isScaledToFit: Bool) -> some View {
        GeometryReader { geo in
            self
                .resizable()
                .aspectRatio(contentMode: isScaledToFit ? .fit : .fill)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

extension UIImage: @retroactive Transferable {
    
    public static var transferRepresentation: some TransferRepresentation {
        
        DataRepresentation(exportedContentType: .png) { image in
            if let pngData = image.pngData() {
                return pngData
            } else {
                // Handle the case where UIImage could not be converted to png.
                throw ConversionError.failedToConvertToPNG
            }
        }
    }
    
    enum ConversionError: Error {
        case failedToConvertToPNG
    }
}
