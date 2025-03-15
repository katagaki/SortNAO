//
//  BlurGradient.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI
import VariableBlurView

struct BlurGradient: View {

    @Environment(\.colorScheme) var colorScheme

    let gradient = LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .black, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )

    var body: some View {
        Group {
            if colorScheme == .dark {
                VariableBlurView()
            } else {
                VariableBlurView()
            }
        }
        .mask(gradient)
        .allowsHitTesting(false)
    }
}
