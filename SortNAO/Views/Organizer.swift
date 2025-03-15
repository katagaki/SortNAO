//
//  Organizer.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI

struct Organizer: View {
    @Environment(SauceNAO.self) var nao

    @State var viewPath: [ViewPath] = []
    @State var isPickingFolder: Bool = false
    @State var apiKeyInput: String = ""

    @State var uncategorized: [URL: Image] = [:]
    @State var categorized: [String: [URL: Image]] = [:]

    @Namespace var namespace

    var body: some View {
        NavigationStack(path: $viewPath) {
            ToroList {
                ToroSection(header: "Welcome to SortNAO") {
                    Text("""
                         To get started, tap \(Image(systemName: "plus")) and select a folder to add your images.
                         """)
                }
                if !nao.isAPIKeySet {
                    ToroSection(header: "Set Up API Key", footer: "You can find your API key in your account page.") {
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
                if uncategorized.count > 0 {
                    ToroSection(
                        header: "Uncategorized",
                        footer: "Select \(Image(systemName: "sparkles.rectangle.stack.fill")) to organize these files.",
                        contentInsets: .init()
                    ) {
                        ImageGrid(
                            images: $uncategorized,
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
                ToroThumbButton(imageName: "plus", action: openPicker)
                ToroThumbButton(
                    imageName: "sparkles.rectangle.stack.fill",
                    accentColor: .send,
                    action: startOrganizingIllustrations
                )
                    .grayscale(nao.isReady ? 0.0 : 1.0)
                    .disabled(!nao.isReady)
            }
            .navigationTitle("SortNAO")
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .account: Color.clear
                case .settings: More()
                case .preview(let imageURL): ImagePreview(imageURL: imageURL, namespace: namespace)
                case .moreAttributions: Licenses()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ToroToolbarButton(iconName: "person.fill", action: openAccountView)
                        ToroToolbarButton(iconName: "ellipsis", action: openSettingsView)
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
                self.uncategorized[imageURL] = Image(uiImage: uiImageDisplay)
            }
        }
    }

    func startOrganizingIllustrations() {
        Task {
            await nao.searchQueue()
        }
    }

    func openPreview(_ imageURL: URL) {
        viewPath.append(.preview(imageURL: imageURL))
    }
}
