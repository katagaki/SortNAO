//
//  ImagePreview.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ImagePreview: View {
    @State var imageURL: URL
    @State var image: UIImage?
    var namespace: Namespace.ID

    var body: some View {
        ZStack(alignment: .center) {
            Color.clear
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear(perform: loadImage)
        .navigationTitle(imageURL.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTransition(.zoom(sourceID: imageURL.absoluteString, in: namespace))
    }

    func loadImage() {
        guard let data = try? Data(contentsOf: imageURL) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.image = uiImage
    }
}
