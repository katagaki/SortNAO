//
//  ToroList.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroList<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20.0) {
                Group {
                    content
                }
                .padding(.horizontal, 20.0)
            }
            .padding(.vertical, 20.0)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.always)
        .scrollIndicators(.never)
        .scrollDismissesKeyboard(.immediately)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
