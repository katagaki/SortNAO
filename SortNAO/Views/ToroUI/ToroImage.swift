//
//  ToroImage.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroImage: View {
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
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24.0, height: 24.0)
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.multicolor)
            }
        }
        .background(.accent)
        .contentShape(.rect)
    }
}
