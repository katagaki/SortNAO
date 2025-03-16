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
    @AppStorage(wrappedValue: true, "Organizer.LoadsSubfolders") var organizerLoadsSubfolders: Bool
    @AppStorage(wrappedValue: true, "API.Sources.Danbooru") var apiSourceDanbooruEnabled: Bool
    @AppStorage(wrappedValue: true, "API.Sources.Gelbooru") var apiSourceGelbooruEnabled: Bool
    @AppStorage(wrappedValue: true, "API.Sources.Pixiv") var apiSourcePixivEnabled: Bool
    @AppStorage(wrappedValue: true, "API.Sources.X") var apiSourceXEnabled: Bool
    @AppStorage(wrappedValue: true, "Organizer.RenameIncludesMaterial") var organizerRenameIncludesMaterial: Bool
    @AppStorage(wrappedValue: true, "Organizer.RenameIncludesCharacters") var organizerRenameIncludesCharacters: Bool
    @AppStorage(wrappedValue: 0, "API.Delay") var apiDelay: Int

    var body: some View {
        MoreList(repoName: "katagaki/SortNAO", viewPath: ViewPath.moreAttributions) {
            Section {
                Toggle("Load From Subfolders", isOn: $organizerLoadsSubfolders)
            } header: {
                ListSectionHeader(text: "Images")
            }
            Section {
                Toggle("Danbooru", isOn: $apiSourceDanbooruEnabled)
                Toggle("Gelbooru", isOn: $apiSourceGelbooruEnabled)
                Toggle("Pixiv", isOn: $apiSourcePixivEnabled)
                Toggle("X (Twitter)", isOn: $apiSourceXEnabled)
            } header: {
                ListSectionHeader(text: "Sources")
            }
            Section {
                Toggle("Include Material Title", isOn: $organizerRenameIncludesMaterial)
                Toggle("Include Character Names", isOn: $organizerRenameIncludesCharacters)
            } header: {
                ListSectionHeader(text: "Filenames")
            }
            Section {
                Picker(selection: $apiDelay) {
                    Text("None")
                        .tag(0)
                    Text("1 Second")
                        .tag(1)
                    Text("3 Seconds")
                        .tag(3)
                    Text("10 Seconds")
                        .tag(10)
                } label: {
                    Text("Delay Between Lookups")
                }
                Button("Reset API Key", role: .destructive, action: resetAPIKey)
            } header: {
                ListSectionHeader(text: "Advanced")
            }
            Section {
                Button("Clear Web Data", role: .destructive, action: clearWebData)
            }
        }
        .listSectionSpacing(.compact)
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
