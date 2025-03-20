//
//  ToroGrid.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroGrid: View {
    @Binding var imageURLs: [URL]
    var previewAction: ((URL) -> Void)
    var namespace: Namespace.ID

    @AppStorage(wrappedValue: .medium, kSImageGridSize) var organizerImageGridSize: GridSize

    init(_ imageURLs: Binding<[URL]>, previewAction: @escaping (URL) -> Void, namespace: Namespace.ID) {
        self._imageURLs = imageURLs
        self.previewAction = previewAction
        self.namespace = namespace
    }

    var body: some View {
        LazyVGrid(
            columns: gridColumns(),
            spacing: 2.0
        ) {
            ForEach(imageURLs, id: \.self) { imageURL in
                Button {
                    previewAction(imageURL)
                } label: {
                    ToroImage(imageURL: imageURL)
                        .matchedGeometryEffect(id: imageURL.absoluteString, in: namespace)
                        .matchedTransitionSource(id: imageURL.absoluteString, in: namespace)
                }
            }
        }
    }

    func gridColumns() -> [GridItem] {
        switch organizerImageGridSize {
        case .small:
            [GridItem(.adaptive(minimum: 40.0), spacing: 1.0)]
        case .medium:
            [GridItem(.adaptive(minimum: 80.0), spacing: 2.0)]
        case .large:
            [GridItem(.adaptive(minimum: 110.0), spacing: 2.0)]
        }
    }
}
