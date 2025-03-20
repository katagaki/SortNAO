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
    @AppStorage(wrappedValue: true, kSAPISourceDanbooru) var apiSourceDanbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceGelbooru) var apiSourceGelbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourcePixiv) var apiSourcePixivEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceX) var apiSourceXEnabled: Bool
    @AppStorage(wrappedValue: 1, kSDelay) var apiDelay: Int

    @State var viewPath: [ViewPath] = []
    @State var isPickingFolder: Bool = false
    @State var isLoadingFiles: Bool = false
    @State var isOrganizing: Bool = false

    @State var apiKeyInput: String = ""

    @Namespace var namespace

    var body: some View {
        @Bindable var nao = nao
        NavigationStack(path: $viewPath) {
            ToroList {
                if nao.queue.isEmpty && nao.queue.isEmpty {
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
                                footer: "Card.Queued.Footer.\(Image(systemName: "sparkles.rectangle.stack.fill"))",
                                contentInsets: .init()) {
                        ToroGrid($nao.queue, previewAction: openPreview, namespace: namespace)
                    }
                }
                if nao.categorized.count > 0 {
                    ForEach(nao.categories, id: \.self) { category in
                        ToroSection(title: "\(category)",
                                    contentInsets: .init()) {
                            ToroGrid(.constant(nao.urls(in: category)),
                                     previewAction: openPreview,
                                     namespace: namespace)
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
                if isOrganizing || isLoadingFiles {
                    ToroThumbActivityIndicator()
                } else {
                    if nao.queue.isEmpty {
                        ToroThumbButton(imageName: "plus", action: openPicker)
                            .accessibilityLabel(Text("Shared.AddFolder"))
                    }
                    if nao.isReady {
                        ToroThumbButton(imageName: "sparkles.rectangle.stack.fill",
                                        accentColor: .send,
                                        action: startOrganizingIllustrations)
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
            UIApplication.shared.isIdleTimerDisabled = true
            withAnimation {
                isLoadingFiles = true
            }
            if url.startAccessingSecurityScopedResource() {
                guard let enumerator = FileManager.default.enumerator(
                    at: url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    return
                }

                let imageExtensions = ["jpg", "jpeg", "png"]
                for case let fileURL as URL in enumerator {
                    do {
                        let attributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                        if attributes.isRegularFile ?? false {
                            let fileExtension = fileURL.pathExtension.lowercased()
                            if imageExtensions.contains(fileExtension) {
                                await nao.add(fileURL)
                            }
                        }
                    } catch {
                        debugPrint(error.localizedDescription, fileURL.absoluteString)
                    }
                }
            }
            withAnimation {
                isLoadingFiles = false
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func startOrganizingIllustrations() {
        Task {
            UIApplication.shared.isIdleTimerDisabled = true
            let sources: [SauceNAO.Source] = [
                (apiSourceDanbooruEnabled ? .danbooru : nil),
                (apiSourceGelbooruEnabled ? .gelbooru : nil),
                (apiSourcePixivEnabled ? .pixiv : nil),
                (apiSourceXEnabled ? .elonX : nil)
            ].compactMap({ $0 })

            withAnimation {
                isOrganizing = true
            }

            for await (imageURL, resultType, result) in nao.searchAll(in: sources, delay: apiDelay) {
                debugPrint(imageURL, resultType, result.debugDescription)
            }

            withAnimation {
                isOrganizing = false
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func retryFailed() {
        withAnimation {
            nao.requeueFailed()
        }
        startOrganizingIllustrations()
    }

    func removeAllFiles() {
        withAnimation {
            nao.clear()
        }
    }

    func openPreview(_ imageURL: URL) {
        viewPath.append(.preview(imageURL: imageURL))
    }
}
