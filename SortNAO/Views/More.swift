//
//  More.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI
import WebKit

struct More: View {
    @Environment(SauceNAO.self) var nao

    var body: some View {
        MoreList(repoName: "katagaki/SortNAO", viewPath: ViewPath.moreAttributions) {
            Button("Reset API Key", role: .destructive, action: resetAPIKey)
            Button("Clear Web Data", role: .destructive, action: clearWebData)
        }
    }

    func resetAPIKey() {
        nao.resetAPIKey()
    }

    func clearWebData() {
        WKWebsiteDataStore.default()
            .fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                records.forEach { record in
                    WKWebsiteDataStore.default().removeData(
                        ofTypes: record.dataTypes,
                        for: [record],
                        completionHandler: {}
                    )
                }
            }
    }
}
