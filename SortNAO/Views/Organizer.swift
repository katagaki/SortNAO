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

    @State var uncategorizedImages: [URL: Image] = [:]
    @State var categorizedImages: [String: [URL: Image]] = [:]
    @State var nonMatchingImages: [URL: Image] = [:]
    @State var failedImages: [URL: Image] = [:]

    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $viewPath) {
            ToroList {
                if uncategorizedImages.isEmpty && categorizedImages.isEmpty {
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
                if uncategorizedImages.count > 0 {
                    ToroSection(
                        header: "Uncategorized",
                        footer: "Tap \(Image(systemName: "sparkles.rectangle.stack.fill")) to organize these images.",
                        contentInsets: .init()
                    ) {
                        ImageGrid(
                            images: $uncategorizedImages,
                            previewImage: openPreview,
                            namespace: namespace
                        )
                    }
                }
                if categorizedImages.count > 0 {
                    ForEach(Array(categorizedImages.keys).sorted(), id: \.self) { category in
                        ToroSection(
                            header: "\(category)",
                            contentInsets: .init()
                        ) {
                            ImageGrid(
                                images: .constant(categorizedImages[category] ?? [:]),
                                previewImage: openPreview,
                                namespace: namespace
                            )
                        }
                    }
                }
                if nonMatchingImages.count > 0 {
                    ToroSection(
                        header: "No Matches",
                        footer: "No similar match was found for these images.",
                        contentInsets: .init()
                    ) {
                        ImageGrid(
                            images: $nonMatchingImages,
                            previewImage: openPreview,
                            namespace: namespace
                        )
                    }
                }
                if failedImages.count > 0 {
                    ToroSection(
                        header: "Failed",
                        footer: "These images could not be looked up.",
                        contentInsets: .init()
                    ) {
                        ImageGrid(
                            images: $nonMatchingImages,
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
                    if !uncategorizedImages.isEmpty || !categorizedImages.isEmpty {
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
                        self.uncategorizedImages[imageURL] = Image(uiImage: uiImageDisplay)
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

            let sources: [SauceNAO.Source] = [
                (apiSourceDanbooruEnabled ? .danbooru : nil),
                (apiSourceGelbooruEnabled ? .gelbooru : nil),
                (apiSourcePixivEnabled ? .pixiv : nil),
                (apiSourceXEnabled ? .elonX : nil)
            ].compactMap({ $0 })

            for await (imageURL, resultType, result) in nao.searchAll(in: sources, delay: apiDelay) {

                switch resultType {
                case .succeeded:
                    guard let result else { continue }

                    let material = result.data.material
                    let characters = result.data.characters
                    let pixivId = result.data.pixivId
                    let xUserHandle = result.data.xUserHandle
                    let category: String? = switch true {
                    case material != nil && characters != nil: "\(material!) - \(characters!)"
                    case pixivId != nil: "Pixiv: \(pixivId!)"
                    case xUserHandle != nil: "X (Twitter): \(xUserHandle!)"
                    default: nil
                    }
                    guard let category else { continue }
                    withAnimation {
                        self.categorizedImages[category, default: [:]][imageURL] = self.uncategorizedImages[imageURL]
                        self.uncategorizedImages.removeValue(forKey: imageURL)
                    }

                case .noMatches:
                    withAnimation {
                        self.nonMatchingImages[imageURL] = self.uncategorizedImages[imageURL]
                        self.uncategorizedImages.removeValue(forKey: imageURL)
                    }

                case .failed:
                    withAnimation {
                        self.failedImages[imageURL] = self.uncategorizedImages[imageURL]
                        self.uncategorizedImages.removeValue(forKey: imageURL)
                    }
                }
            }

            withAnimation {
                isOrganizing = false
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    func removeAllFiles() {
        withAnimation {
            uncategorizedImages.removeAll()
            categorizedImages.removeAll()
            nonMatchingImages.removeAll()
        }
        nao.clear()
    }

    func openPreview(_ imageURL: URL) {
        viewPath.append(.preview(imageURL: imageURL))
    }
}
// swiftlint:enable type_body_length
