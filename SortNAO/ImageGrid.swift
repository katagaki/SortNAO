//
//  ImageGrid.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ImageGrid: View {
    @State var images: [Any] = []
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 80.0), spacing: 2.0)],
            spacing: 2.0
        ) {
            // TODO: Use actual images
            ForEach(0...(.random(in: 10...50)), id: \.self) { _ in
                Button(action: doNothing) {
                    ToroImage()
                }
            }
        }
    }

    func doNothing() {
        
    }
}
