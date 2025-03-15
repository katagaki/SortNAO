//
//  ImageGrid.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ImageGrid: View {
    @Binding var images: [URL: Image]
    var previewImage: ((URL) -> Void)
    var namespace: Namespace.ID

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80.0), spacing: 2.0)],
            spacing: 2.0
        ) {
            ForEach(
                Array(images.keys).sorted(by: { $0.absoluteString < $1.absoluteString }),
                id: \.self
            ) { imageURL in
                Button {
                    previewImage(imageURL)
                } label: {
                    ToroImage(image: images[imageURL]!)
                        .matchedTransitionSource(id: imageURL.absoluteString, in: namespace)
                }
            }
        }
    }
}
