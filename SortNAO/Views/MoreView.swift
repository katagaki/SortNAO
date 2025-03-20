//
//  More.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI
import WebKit

struct MoreView: View {
    @Environment(SauceNAO.self) var nao
    @AppStorage(wrappedValue: .medium, kSImageGridSize) var organizerImageGridSize: GridSize
    @AppStorage(wrappedValue: true, kSLoadsSubfolders) var organizerLoadsSubfolders: Bool
    @AppStorage(wrappedValue: true, kSAPISourceDanbooru) var apiSourceDanbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceGelbooru) var apiSourceGelbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourcePixiv) var apiSourcePixivEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceX) var apiSourceXEnabled: Bool
    @AppStorage(wrappedValue: true, kSRenameIncludesMaterial) var organizerRenameIncludesMaterial: Bool
    @AppStorage(wrappedValue: true, kSRenameIncludesCharacter) var organizerRenameIncludesCharacters: Bool
    @AppStorage(wrappedValue: 1, kSDelay) var apiDelay: Int

    var body: some View {
        MoreList(repoName: "katagaki/SortNAO", viewPath: ViewPath.moreAttributions) {
            Section {
                Picker(selection: $organizerImageGridSize) {
                    Text("GridSize.Small")
                        .tag(GridSize.small)
                    Text("GridSize.Medium")
                        .tag(GridSize.medium)
                    Text("GridSize.Large")
                        .tag(GridSize.large)
                } label: {
                    Text("GridSize.Title")
                }

                Toggle("Images.LoadSubfolders", isOn: $organizerLoadsSubfolders)
            } header: {
                ListSectionHeader(text: "More.Sections.Images")
            }
            Section {
                Toggle("Source.Danbooru", isOn: $apiSourceDanbooruEnabled)
                Toggle("Source.Gelbooru", isOn: $apiSourceGelbooruEnabled)
                Toggle("Source.Pixiv", isOn: $apiSourcePixivEnabled)
                Toggle("Source.ElonX", isOn: $apiSourceXEnabled)
            } header: {
                ListSectionHeader(text: "More.Sections.Sources")
            }
            Section {
                Toggle("Filenames.IncludeMaterial", isOn: $organizerRenameIncludesMaterial)
                Toggle("Filenames.IncludeCharacter", isOn: $organizerRenameIncludesCharacters)
            } header: {
                ListSectionHeader(text: "More.Sections.Filenames")
            }
            Section {
                Picker(selection: $apiDelay) {
                    Text("API.Delay.\(0)")
                        .tag(0)
                    Text("API.Delay.\(1)")
                        .tag(1)
                    Text("API.Delay.\(3)")
                        .tag(3)
                    Text("API.Delay.\(10)")
                        .tag(10)
                } label: {
                    Text("API.Delay.Title")
                }
                Button("API.Key.Reset", role: .destructive, action: resetAPIKey)
                Button("Shared.ClearWebData", role: .destructive, action: clearWebData)
            } header: {
                ListSectionHeader(text: "More.Sections.Advanced")
            } footer: {
                if apiDelay < 1 {
                    Text("API.Delay.Footer")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.red)
                }
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
