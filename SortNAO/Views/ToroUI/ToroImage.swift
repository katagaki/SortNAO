//
//  ToroImage.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroImage: View {
    @Environment(SauceNAO.self) var nao

    @State var imageURL: URL
    @State var image: Image?

    var body: some View {
        ZStack(alignment: .center ) {
            Color.clear
            if let image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .aspectRatio(1.0, contentMode: .fill)
                    .clipped()
            } else {
                ProgressView()
            }
        }
        .background(.accent.quinary)
        .aspectRatio(1.0, contentMode: .fill)
        .contentShape(.rect)
        .task {
            if image == nil {
                guard let uiImageDisplay = await nao.thumbnail(imageURL) else { return }
                image = Image(uiImage: uiImageDisplay)
            }
        }
    }
}
