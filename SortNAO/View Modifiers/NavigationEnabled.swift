//
//  Untitled.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import SwiftUI

struct NavigationEnabled: ViewModifier {
    var namespace: Namespace.ID

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .account: AccountView()
                case .preview(let imageURL): ImagePreview(imageURL: imageURL, namespace: namespace)
                case .more: MoreView()
                case .moreAttributions: MoreLicensesView()
                }
            }
    }
}

extension View {
    func navigationEnabled(namespace: Namespace.ID) -> some View {
        self.modifier(NavigationEnabled(namespace: namespace))
    }
}
