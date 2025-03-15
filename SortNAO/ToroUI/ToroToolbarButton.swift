//
//  ToroToolbarButton.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroToolbarButton: View {
    @State var iconName: String
    @State var action: (() -> Void)
    var body: some View {
        Button {
            action()
        } label: {
            ZStack(alignment: .center) {
                Circle()
                    .foregroundStyle(.tertiary)
                    .frame(width: 26.0, height: 26.0)
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16.0, height: 16.0)
                    .symbolRenderingMode(.monochrome)
            }
        }
        .tint(.primary)
    }
}
