//
//  ToroSection.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroSection<Content: View>: View {
    @State var header: LocalizedStringKey? = nil
    @State var footer: LocalizedStringKey? = nil
    @State var contentInsets: EdgeInsets = EdgeInsets(top: 8.0, leading: 16.0, bottom: 8.0, trailing: 16.0)
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            if let header {
                HStack {
                    Text(header)
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 16.0)
                        .padding(.vertical, 8.0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            }
            VStack(alignment: .leading, spacing: 10.0) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(contentInsets)
            .background(.ultraThinMaterial.opacity(0.5))
            if let footer {
                HStack {
                    Text(footer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16.0)
                        .padding(.vertical, 8.0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.backgroundGradientTop.opacity(0.3))
        .clipShape(.rect(cornerRadius: 10.0))
        .compositingGroup()
        .shadow(color: .black.opacity(0.15), radius: 8.0, y: 5.0)
    }
}
