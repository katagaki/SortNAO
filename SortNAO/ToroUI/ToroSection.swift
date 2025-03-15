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
                Text(header)
                    .font(.subheadline)
                    .bold()
                    .padding(.horizontal, 16.0)
                    .padding(.vertical, 8.0)
                Divider()
            }
            VStack(alignment: .leading, spacing: 10.0) {
                content
            }
            .padding(contentInsets)
            if let footer {
                Divider()
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16.0)
                    .padding(.vertical, 8.0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
        .clipShape(.rect(cornerRadius: 10.0))
        .shadow(color: .black.opacity(0.1), radius: 8.0, y: 5.0)
    }
}
