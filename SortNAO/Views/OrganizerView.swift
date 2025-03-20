//
//  OrganizerView.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI

struct OrganizerView: View {
    @Environment(SauceNAO.self) var nao
    @AppStorage(wrappedValue: true, kSLoadsSubfolders) var organizerLoadsSubfolders: Bool
    @AppStorage(wrappedValue: true, kSAPISourceDanbooru) var apiSourceDanbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceGelbooru) var apiSourceGelbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourcePixiv) var apiSourcePixivEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceX) var apiSourceXEnabled: Bool
    @AppStorage(wrappedValue: true, kSRenameIncludesMaterial) var organizerRenameIncludesMaterial: Bool
    @AppStorage(wrappedValue: true, kSRenameIncludesCharacter) var organizerRenameIncludesCharacters: Bool
    @AppStorage(wrappedValue: 1, kSDelay) var apiDelay: Int

    @State var viewPath: [ViewPath] = []
    @State var isFirstBatchOfFilesOpened: Bool = false
    @State var isPickingFolder: Bool = false
    @State var isLoadingFiles: Bool = false
    @State var isSearching: Bool = false
    @State var isOrganizing: Bool = false
    @State var isConfirmingRename: Bool = false
    @State var isRenaming: Bool = false
    @State var isRenameComplete: Bool = false

    @State var renameExamples: String = ""
    @State var renameCount: Int = 0

    @State var apiKeyInput: String = ""

    @Namespace var namespace

    var body: some View {
        @Bindable var nao = nao
        NavigationStack(path: $viewPath) {
            ToroList {
                if !isFirstBatchOfFilesOpened {
                    ToroSection(title: "Card.Welcome.Title") {
                        Text("Card.Welcome.Description.\(Image(systemName: "plus"))")
                    }
                }
                if !nao.isAPIKeySet {
                    ToroSection(title: "Card.APIKey.Title",
                                footer: "Card.APIKey.Description.\(Image(systemName: "person.fill"))") {
                    Text("Card.APIKey.Input.Title")
                        SecureField("Card.APIKey.Input.Placeholder", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                        Button(action: setAPIKey) {
                            Label("Shared.Save", systemImage: "key.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(.capsule)
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces) == "")
                    }
                }
                if nao.queue.count > 0 {
                    ToroSection(title: "Card.Queued.Title",
                                footer: "Card.Queued.Footer.\(Image(systemName: "sparkle.magnifyingglass"))",
                                contentInsets: .init()) {
                        ToroGrid($nao.queue, previewAction: openPreview, namespace: namespace)
                    }
                }
                if nao.categories.count > 0 {
                    ForEach(nao.categories, id: \.self) { category in
                        ToroSection(titleAttributed: category.displayName(),
                                    contentInsets: .init()) {
                            ToroGrid(.constant(nao.urls(in: category)),
                                     previewAction: openPreview,
                                     namespace: namespace)
                        } header: {
                            Group {
                                switch category.source {
                                case .danbooru: Image(.sourceDanbooru).resizable()
                                case .gelbooru: Image(.sourceGelbooru).resizable()
                                case .pixiv: Image(.sourcePixiv).resizable()
                                case .elonX: Image(.sourceElonX).resizable()
                                default: Color.clear
                                }
                            }
                            .clipShape(.rect(cornerRadius: 6.0))
                            .frame(width: 24.0, height: 24.0)
                            .overlay {
                                RoundedRectangle(cornerRadius: 6.0)
                                    .stroke(.primary.tertiary, lineWidth: 1 / 3)
                            }
                        }
                    }
                }
                if nao.noMatches.count > 0 {
                    ToroSection(title: "Card.NoMatches.Title",
                                footer: "Card.NoMatches.Description",
                                contentInsets: .init()) {
                        ToroGrid(.constant(nao.noMatchesURLs),
                                 previewAction: openPreview,
                                 namespace: namespace)
                    }
                }
                if nao.failed.count > 0 {
                    ToroSection(title: "Card.Failed.Title",
                                footer: "Card.Failed.Description",
                                contentInsets: .init()) {
                        ToroGrid($nao.failed, previewAction: openPreview, namespace: namespace)
                    } header: {
                        Button("Shared.Retry", systemImage: "arrow.clockwise", action: retryFailed)
                    }
                }
            }
            #if !targetEnvironment(macCatalyst)
            .background(
                .linearGradient(
                    colors: [.backgroundGradientTop, .backgroundGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            #endif
            .bottomAccessoryBar {
                if isSearching || isLoadingFiles || isRenaming {
                    ToroThumbActivityIndicator()
                } else {
                    if nao.queue.isEmpty {
                        ToroThumbButton(imageName: "plus", action: openPicker)
                            .accessibilityLabel(Text("Shared.AddFolder"))
                    }
                    if nao.isReady {
                        ToroThumbButton(imageName: "sparkle.magnifyingglass",
                                        accentColor: .send,
                                        action: startImageSearch)
                        .accessibilityLabel(Text("Shared.Images.Search"))
                    }
                    if !nao.categories.isEmpty {
                        ToroThumbButton(imageName: "sparkles.rectangle.stack.fill",
                                        accentColor: .confirm,
                                        action: confirmRename)
                        .accessibilityLabel(Text("Shared.Images.Organize"))
                    }
                    if !nao.queue.isEmpty || !nao.categorized.isEmpty {
                        ToroThumbButton(imageName: "trash.fill", accentColor: .red, action: removeAllFiles)
                            .accessibilityLabel(Text("Shared.Images.RemoveAll"))
                    }
                }
            }
            .navigationTitle("SortNAO")
            .navigationEnabled(namespace: namespace)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ToroToolbarButton(iconName: "person.fill", action: openAccountView)
                            .accessibilityLabel(Text("Shared.Account"))
                        ToroToolbarButton(iconName: "ellipsis", action: openSettingsView)
                            .accessibilityLabel(Text("Shared.More"))
                    }
                }
            }
            .sheet(isPresented: $isPickingFolder) {
                FolderPicker(onFolderPicked: loadFolderContents)
            }
            .alert(
                "Alert.ConfirmOrganize",
                isPresented: $isOrganizing
            ) {
                Button("Shared.RenameFiles", action: {})
                Button("Shared.SortIntoFolders", action: {})
                Button("Shared.Cancel", role: .cancel, action: {})
            }
            .alert(
                "Alert.ConfirmRename.\(self.renameExamples)",
                isPresented: $isConfirmingRename
            ) {
                Button("Shared.Start", action: startFileRename)
                Button("Shared.Cancel", role: .cancel, action: {})
            }
            .alert(
                "Alert.RenameComplete.\(self.renameCount)",
                isPresented: $isRenameComplete
            ) {
                Button("Shared.OK", role: .cancel, action: {})
            }
        }
    }

    func setAPIKey() {
        withAnimation {
            nao.setAPIKey(apiKeyInput)
        } completion: {
            apiKeyInput = ""
        }
    }

    func openAccountView() {
        viewPath.append(.account)
    }

    func openSettingsView() {
        viewPath.append(.more)
    }

    func openPicker() {
        isPickingFolder = true
    }

    func loadFolderContents(url: URL) {
        Task {
            isFirstBatchOfFilesOpened = true
            UIApplication.shared.isIdleTimerDisabled = true
            withAnimation { isLoadingFiles = true }
            await nao.add(folder: url, includesSubdirectories: organizerLoadsSubfolders)
            withAnimation { isLoadingFiles = false }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func startImageSearch() {
        Task {
            UIApplication.shared.isIdleTimerDisabled = true
            let sources: [SauceNAO.Source] = [
                (apiSourceDanbooruEnabled ? .danbooru : nil),
                (apiSourceGelbooruEnabled ? .gelbooru : nil),
                (apiSourcePixivEnabled ? .pixiv : nil),
                (apiSourceXEnabled ? .elonX : nil)
            ].compactMap({ $0 })
            withAnimation { isSearching = true }
            for await (imageURL, resultType, result) in nao.searchAll(in: sources, delay: apiDelay) {
                debugPrint(imageURL, resultType, result.debugDescription)
            }
            withAnimation { isSearching = false }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func startFileRename() {
        Task {
            UIApplication.shared.isIdleTimerDisabled = true
            self.renameExamples = ""
            self.renameCount = 0
            withAnimation { isRenaming = true }
            for await (url, newURL) in nao.renameAll(
                includeMaterialName: organizerRenameIncludesMaterial,
                includeCharacterNames: organizerRenameIncludesCharacters
            ) {
                debugPrint(url.lastPathComponent, newURL.lastPathComponent)
                self.renameCount += 1
            }
            withAnimation { isRenaming = false }
            UIApplication.shared.isIdleTimerDisabled = false
            self.isRenameComplete = true
        }
    }

    func confirmRename() {
        Task {
            var renameExamples: [String] = []
            for await (url, newURL) in nao.renameAll(
                includeMaterialName: organizerRenameIncludesMaterial,
                includeCharacterNames: organizerRenameIncludesCharacters,
                rehearse: true
            ) {
                renameExamples.append("\(url.lastPathComponent) → \(newURL.lastPathComponent)")
            }
            self.renameExamples = renameExamples.joined(separator: "\n")
            self.isConfirmingRename = true
        }
    }

    func retryFailed() {
        withAnimation { nao.requeueFailed() }
        startImageSearch()
    }

    func removeAllFiles() {
        withAnimation { nao.clear() }
    }

    func openPreview(_ imageURL: URL) {
        viewPath.append(.preview(imageURL: imageURL))
    }
}
