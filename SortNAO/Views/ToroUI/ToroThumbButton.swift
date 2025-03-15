//
//  ToroThumbButton.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroThumbButton: View {
    @State var imageName: String
    @State var accentColor: Color?
    @State var action: (() -> Void)

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(accentColor == nil ? .accent : accentColor!)
                    .frame(width: 72.0, height: 72.0)
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32.0, height: 32.0)
                    .foregroundStyle(.white)
            }
        }
        .clipShape(.circle)
    }
}
