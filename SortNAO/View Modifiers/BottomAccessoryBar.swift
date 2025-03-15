//
//  BottomAccessoryBar.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct BottomAccessoryBar: ViewModifier {
    var addAction: (() -> Void)
    var organizeAction: (() -> Void)

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                BlurGradient()
                    .background(
                        .linearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: Color(uiColor: .systemBackground).opacity(0.0), location: 0.6),
                                .init(color: .backgroundGradientBottom, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom)
                    )
                    .frame(maxWidth: .infinity, minHeight: 180.0, maxHeight: 180.0)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .safeAreaInset(edge: .bottom, spacing: 0.0) {
                HStack(alignment: .center, spacing: 20.0) {
                    Group {
                        ToroThumbButton(imageName: "plus", action: addAction)
                        ToroThumbButton(imageName: "sparkles.rectangle.stack.fill", accentColor: .send, action: organizeAction)
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4.0, y: 3.0)
                }
                .padding(10.0)
                .frame(maxWidth: .infinity, alignment: .center)
            }
    }
}

extension View {
    func bottomAccessoryBar(
        addAction: @escaping (() -> Void),
        organizeAction: @escaping (() -> Void)
    ) -> some View {
        self.modifier(BottomAccessoryBar(
            addAction: addAction,
            organizeAction: organizeAction
        ))
    }
}
