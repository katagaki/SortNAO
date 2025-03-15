//
//  OrganizerView.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI

struct OrganizerView: View {
    @State var nao: SauceNAO = SauceNAO()
    @State var viewPath: [ViewPath] = []
    @State var isPickingFolder: Bool = false
    @State var apiKey: String = ""
    
    @State var uncategorized: [URL: Image] = [:]
    @State var categorized: [URL: [UIImage]] = [:]
    
    @Namespace var namespace
    
    var body: some View {
        NavigationStack(path: $viewPath) {
            ToroList {
                ToroSection(header: "Welcome to SortNAO") {
                    Text("""
                         To get started, tap \(Image(systemName: "plus")) and select a folder to add your images.
                         """)
                }
                ToroSection(header: "Set Up API Key") {
                    Text("Enter your SauceNAO API key below.")
                    SecureField("SauceNAO API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    ActionButton(text: "Save", icon: "key.fill", isPrimary: true, action: setAPIKey)
                }
                if uncategorized.count > 0 {
                    ToroSection(header: "Uncategorized", footer: "Select \(Image(systemName: "sparkles.rectangle.stack.fill")) to organize these files.", contentInsets: .init()) {
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
                ToroThumbButton(imageName: "sparkles.rectangle.stack.fill", accentColor: .send, action: startOrganizingIllustrations)
            }
            .navigationTitle("SortNAO")
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .account: Color.clear
                case .settings: SettingsView()
                case .preview(let imageURL): ImagePreview(imageURL: imageURL, namespace: namespace)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        ToroToolbarButton(iconName: "person.fill", action: openAccountView)
                        ToroToolbarButton(iconName: "gearshape.fill", action: openSettingsView)
                    }
                }
            }
            .sheet(isPresented: $isPickingFolder) {
                FolderPicker(onFolderPicked: loadFolderContents)
            }
        }
    }
    
    func setAPIKey() {
        nao.setAPIKey(apiKey)
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
                            let data = try Data(contentsOf: fileURL)
                            nao.queue(fileURL, data: data)
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
                guard let uiImageDisplay = await uiImage.byPreparingForDisplay() else {
                    continue
                }
                self.uncategorized[imageURL] = Image(uiImage: uiImageDisplay)
            }
        }
    }
    
    func startOrganizingIllustrations() {
        
    }

    func openPreview(_ imageURL: URL) {
        viewPath.append(.preview(imageURL: imageURL))
    }
}
