//
//  ToroSection.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

struct ToroSection<Content: View, HeaderContent: View>: View {
    @State var title: LocalizedStringKey?
    @State var footer: LocalizedStringKey?
    @State var contentInsets: EdgeInsets = EdgeInsets(top: 10.0, leading: 16.0, bottom: 10.0, trailing: 16.0)
    @ViewBuilder var content: Content
    @ViewBuilder var header: HeaderContent

    init(
        title: LocalizedStringKey? = nil,
        footer: LocalizedStringKey? = nil,
        contentInsets: EdgeInsets? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> HeaderContent
    ) {
        self.title = title
        self.footer = footer
        if let contentInsets {
            self.contentInsets = contentInsets
        }
        self.content = content()
        self.header = header()
    }

    init(
        title: LocalizedStringKey? = nil,
        footer: LocalizedStringKey? = nil,
        contentInsets: EdgeInsets? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where HeaderContent == EmptyView {
        self.title = title
        self.footer = footer
        if let contentInsets {
            self.contentInsets = contentInsets
        }
        self.content = content()
        self.header = EmptyView()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            if let title {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .bold()
                    Spacer(minLength: .zero)
                    header
                        .font(.subheadline)
                        .buttonStyle(.plain)
                }
                .padding(.horizontal, 16.0)
                .padding(.vertical, 8.0)
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
