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
    var label: LocalizedStringKey?
    @State var action: (() -> Void)

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8.0) {
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
                if let label {
                    Text(label)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.primary)
                }
            }
        }
        .buttonStyle(.plain)
        .buttonBorderShape(.circle)
    }
}
