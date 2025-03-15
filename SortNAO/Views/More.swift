//
//  More.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI

struct More: View {
    @Environment(SauceNAO.self) var nao

    var body: some View {
        MoreList(repoName: "katagaki/SortNAO", viewPath: ViewPath.moreAttributions) {
            Button("Reset API Key", role: .destructive, action: resetAPIKey)
        }
    }

    func resetAPIKey() {
        nao.resetAPIKey()
    }
}
