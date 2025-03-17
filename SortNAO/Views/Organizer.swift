//
//  Organizer.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI

// swiftlint:disable type_body_length
struct Organizer: View {
    @Environment(SauceNAO.self) var nao
    @AppStorage(wrappedValue: true, kSAPISourceDanbooru) var apiSourceDanbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceGelbooru) var apiSourceGelbooruEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourcePixiv) var apiSourcePixivEnabled: Bool
    @AppStorage(wrappedValue: true, kSAPISourceX) var apiSourceXEnabled: Bool
    @AppStorage(wrappedValue: 0, kSDelay) var apiDelay: Int

    @State var viewPath: [ViewPath] = []
    @State var isPickingFolder: Bool = false
    @State var isLoadingFiles: Bool = false
    @State var isOrganizing: Bool = false

    @State var apiKeyInput: String = ""

    @State var uncategorized: [URL: Image] = [:]
    @State var noMatches: [URL: Image] = [:]
    @State var categorized: [String: [URL: Image]] = [:]

    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $viewPath) {
            ToroList {
                if uncategorized.isEmpty && categorized.isEmpty {
                    ToroSection(header: "Welcome to SortNAO") {
                        Text("""
                             To get started, tap \(Image(systemName: "plus")) and select a folder to add your images.
                             """)
                    }
                }
                // swiftlint:disable line_length
                if !nao.isAPIKeySet {
                    ToroSection(
                        header: "Set Up API Key",
                        footer: "Tap the \(Image(systemName: "person.fill")) icon on the menu bar to open your account page."
                    ) {
                    Text("Enter your SauceNAO API key below.")
                        SecureField("SauceNAO API Key", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                        Button(action: setAPIKey) {
                            Label("Save", systemImage: "key.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(.capsule)
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces) == "")
                    }
                }
                // swiftlint:enable line_length
                if uncategorized.count > 0 {
                    ToroSection(
                        header: "Uncategorized",
                        footer: "Tap \(Image(systemName: "sparkles.rectangle.stack.fill")) to organize these images.",
                        contentInsets: .init()
                    ) {
                        ImageGrid(
                            images: $uncategorized,
                            previewImage: openPreview,
                            namespace: namespace
                        )
                    }
                }
                if categorized.count > 0 {
                    ForEach(Array(categorized.keys).sorted(), id: \.self) { category in
                        ToroSection(
                            header: "\(category)",
                            contentInsets: .init()
                        ) {
                            ImageGrid(
                                images: .constant(categorized[category] ?? [:]),
                                previewImage: openPreview,
                                namespace: namespace
                            )
                        }
                    }
                }
                if noMatches.count > 0 {
                    ToroSection(
                        header: "No Matches",
                        footer: "No similar match was found for these images.",
                        contentInsets: .init()
                    ) {
                        ImageGrid(
                            images: $noMatches,
                            previewImage: openPreview,
                            namespace: namespace
                        )
                    }
                }
            }
            .background(
                .linearGradient(
                    colors: [.backgroundGradientTop, .backgroundGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .bottomAccessoryBar {
                if isOrganizing || isLoadingFiles {
                    ToroThumbActivityIndicator()
                } else {
                    ToroThumbButton(imageName: "plus", action: openPicker)
                        .accessibilityLabel(Text("Add Folder"))
                    if nao.isReady {
                        ToroThumbButton(
                            imageName: "sparkles.rectangle.stack.fill",
                            accentColor: .send,
                            action: startOrganizingIllustrations
                        )
                        .accessibilityLabel(Text("Organize Images"))
                    }
                    if !uncategorized.isEmpty || !categorized.isEmpty {
                        ToroThumbButton(imageName: "trash.fill", accentColor: .red, action: removeAllFiles)
                            .accessibilityLabel(Text("Remove All Images"))
                    }
                }
            }
            .navigationTitle("SortNAO")
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .account: Account()
                case .settings: More()
                case .preview(let imageURL): ImagePreview(imageURL: imageURL, namespace: namespace)
                case .moreAttributions: Licenses()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ToroToolbarButton(iconName: "person.fill", action: openAccountView)
                            .accessibilityLabel(Text("Account"))
                        ToroToolbarButton(iconName: "ellipsis", action: openSettingsView)
                            .accessibilityLabel(Text("More"))
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
        viewPath.append(.settings)
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
                                nao.queue(fileURL)
                            }
                        }
                    } catch {
                        debugPrint(error.localizedDescription, fileURL.absoluteString)
                    }
                }

                for (imageURL, imageData) in nao.queue {
                    guard let uiImage = UIImage(data: imageData) else {
                        continue
                    }
                    guard let uiImageDisplay = await uiImage.byPreparingThumbnail(
                        ofSize: CGSize(width: 200.0, height: 200.0)
                    ) else {
                        continue
                    }
                    withAnimation {
                        self.uncategorized[imageURL] = Image(uiImage: uiImageDisplay)
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
            withAnimation {
                isOrganizing = true
            }
            
            var sources: [SauceNAO.Source] = []
            if apiSourceDanbooruEnabled { sources.append(.danbooru) }
            if apiSourceGelbooruEnabled { sources.append(.gelbooru) }
            if apiSourcePixivEnabled { sources.append(.pixiv) }
            if apiSourceXEnabled { sources.append(.x) }

            for await (imageURL, searchResponse) in nao.searchAll(in: sources, delay: apiDelay) {

                // Choose the highest matching result
                var results = searchResponse.results
                if results.count > 1 {
                    results.sort { $0.header.similarityValue() > $1.header.similarityValue() }
                }
                guard let chosenResult = results.first else {
                    sendToNoMatchBin(imageURL)
                    continue
                }
                if chosenResult.header.similarityValue() < 65.0 {
                    sendToNoMatchBin(imageURL)
                    continue
                }

                // Sort into proper category
                let material = chosenResult.data.material
                let characters = chosenResult.data.characters
                let pixivId = chosenResult.data.pixivId
                let xUserHandle = chosenResult.data.xUserHandle
                let category: String? = switch true {
                case material != nil && characters != nil: "\(material!) - \(characters!)"
                case pixivId != nil: "Pixiv: \(pixivId!)"
                case xUserHandle != nil: "X (Twitter): \(xUserHandle!)"
                default: nil
                }
                guard let category else {
                    sendToNoMatchBin(imageURL)
                    continue
                }

                withAnimation {
                    self.categorized[category, default: [:]][imageURL] = self.uncategorized[imageURL]
                    self.uncategorized.removeValue(forKey: imageURL)
                }
            }

            withAnimation {
                isOrganizing = false
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func sendToNoMatchBin(_ imageURL: URL) {
        withAnimation {
            self.noMatches[imageURL] = self.uncategorized[imageURL]
            self.uncategorized.removeValue(forKey: imageURL)
        }
    }

    func removeAllFiles() {
        withAnimation {
            uncategorized.removeAll()
            categorized.removeAll()
            noMatches.removeAll()
        }
        nao.clear()
    }

    func openPreview(_ imageURL: URL) {
        viewPath.append(.preview(imageURL: imageURL))
    }
}
// swiftlint:enable type_body_length
