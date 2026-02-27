//
//  ActionViewController.swift
//  SortNAOAction
//
//  Created by Claude on 2026/02/26.
//

import KeychainAccess
import SwiftUI
import UIKit
import UniformTypeIdentifiers

class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = ActionViewModel(extensionContext: extensionContext)
        let openURLAction = OpenURLAction { [weak self] url in
            self?.extensionContext?.open(url, completionHandler: nil)
            return .handled
        }
        let hostingController = UIHostingController(
            rootView: ActionContentView(viewModel: viewModel)
                .environment(\.openURL, openURLAction)
        )
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        hostingController.didMove(toParent: self)
    }
}

// MARK: - SwiftUI View

struct ActionContentView: View {
    @State var viewModel: ActionViewModel

    var body: some View {
        NavigationStack {
            List {
                imageSection
                statusSection
                resultsSections
            }
            .listStyle(.insetGrouped)
            .navigationTitle("SortNAO")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("Shared.Done", comment: "")) {
                        viewModel.done()
                    }
                }
            }
        }
        .task {
            await viewModel.loadImageFromExtensionContext()
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        if let image = viewModel.image {
            Section {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if viewModel.isSearching || !viewModel.statusMessage.isEmpty {
            Section {
                if viewModel.isSearching {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(viewModel.statusMessage)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text(viewModel.statusMessage)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    @ViewBuilder
    private var resultsSections: some View {
        ForEach(Array(viewModel.results.enumerated()), id: \.offset) { _, result in
            Section {
                Text("\(result.header.similarity)% match")
                    .font(.headline)
                    .foregroundStyle(
                        (Double(result.header.similarity) ?? 0) >= 65.0 ? Color.green : Color.orange
                    )

                if let material = result.data.material, !material.isEmpty {
                    LabeledContent(NSLocalizedString("Action.Material", comment: ""), value: material)
                }

                if let characters = result.data.characters, !characters.isEmpty {
                    LabeledContent(NSLocalizedString("Action.Characters", comment: ""), value: characters)
                }

                if let creator = result.data.creator, !creator.isEmpty {
                    LabeledContent(NSLocalizedString("Action.Creator", comment: ""), value: creator)
                }

                if let memberName = result.data.memberName {
                    LabeledContent(NSLocalizedString("Action.Artist", comment: ""), value: memberName)
                }

                if let xHandle = result.data.xUserHandle {
                    LabeledContent("X", value: "@\(xHandle)")
                }

                if let urls = result.data.externalURLs, !urls.isEmpty {
                    ForEach(urls, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            Link(urlString, destination: url)
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            }
        }
    }

    private var imageCornerRadius: CGFloat {
        if #available(iOS 26.0, *) {
            return 20.0
        } else {
            return 8.0
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
class ActionViewModel {
    var image: UIImage?
    var isSearching: Bool = false
    var statusMessage: String = ""
    var results: [ActionSearchResult] = []

    private let extensionContext: NSExtensionContext?
    private let keychain = Keychain(service: "com.tsubuzaki.SortNAO")
    private let keychainAPIKeyKey = "SauceNAOAPIKey"
    private let endpoint = URL(string: "https://saucenao.com/search.php")!

    init(extensionContext: NSExtensionContext?) {
        self.extensionContext = extensionContext
    }

    func done() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    func loadImageFromExtensionContext() async {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            statusMessage = "No input items found."
            return
        }

        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    do {
                        let data = try await loadItemAsync(attachment: attachment)
                        if let url = data as? URL,
                           let imageData = try? Data(contentsOf: url),
                           let loadedImage = UIImage(data: imageData) {
                            image = loadedImage
                            await searchSauce(for: loadedImage)
                        } else if let imageData = data as? Data,
                                  let loadedImage = UIImage(data: imageData) {
                            image = loadedImage
                            await searchSauce(for: loadedImage)
                        } else if let loadedImage = data as? UIImage {
                            image = loadedImage
                            await searchSauce(for: loadedImage)
                        } else {
                            statusMessage = "Could not load image."
                        }
                    } catch {
                        statusMessage = "Could not load image: \(error.localizedDescription)"
                    }
                    return
                }
            }
        }

        statusMessage = "No image found in the shared content."
    }

    private func loadItemAsync(attachment: NSItemProvider) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            attachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        }
    }

    private func searchSauce(for image: UIImage) async {
        guard let apiKey = try? keychain.get(keychainAPIKeyKey) else {
            statusMessage = "No SauceNAO API key set. Please set your API key in the SortNAO app first."
            return
        }

        isSearching = true
        statusMessage = NSLocalizedString("Action.Searching", comment: "")

        do {
            let response = try await performSearch(image: image, apiKey: apiKey)
            isSearching = false
            processResults(response)
        } catch {
            isSearching = false
            statusMessage = "Search failed: \(error.localizedDescription)"
        }
    }

    private func processResults(_ response: ActionSearchResponse) {
        let sorted = response.results.sorted {
            (Double($0.header.similarity) ?? 0) > (Double($1.header.similarity) ?? 0)
        }

        if sorted.isEmpty {
            statusMessage = NSLocalizedString("Action.NoResults", comment: "")
            return
        }

        statusMessage = NSLocalizedString("Action.ResultsFound", comment: "")
        results = sorted
    }

    private func performSearch(image: UIImage, apiKey: String) async throws -> ActionSearchResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw SearchError.invalidImage
        }

        let boundary = "----------SortNAOBoundary\(UUID().uuidString.prefix(16))"
        var components = URLComponents(string: endpoint.absoluteString)!
        components.queryItems = [
            URLQueryItem(name: "output_type", value: "2"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "numres", value: "5")
        ]

        guard let url = components.url else {
            throw SearchError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!
        )
        body.append("Content-Type: image/jpeg\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (responseData, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ActionSearchResponse.self, from: responseData)
    }

    enum SearchError: Error {
        case invalidImage
        case invalidURL
    }
}

// MARK: - Models

struct ActionSearchResponse: Codable {
    var results: [ActionSearchResult]
}

struct ActionSearchResult: Codable {
    var header: ResultHeader
    var data: ResultData

    struct ResultHeader: Codable {
        var similarity: String
        var thumbnail: String
        var indexId: Int
        var indexName: String

        enum CodingKeys: String, CodingKey {
            case similarity
            case thumbnail
            case indexId = "index_id"
            case indexName = "index_name"
        }
    }

    struct ResultData: Codable {
        var externalURLs: [String]?
        var danbooruId: Int?
        var gelbooruId: Int?
        var creator: String?
        var material: String?
        var characters: String?
        var source: String?
        var title: String?
        var pixivId: Int?
        var memberName: String?
        var memberId: Int?
        var xUserHandle: String?

        enum CodingKeys: String, CodingKey {
            case externalURLs = "ext_urls"
            case danbooruId = "danbooru_id"
            case gelbooruId = "gelbooru_id"
            case creator
            case material
            case characters
            case source
            case title
            case pixivId = "pixiv_id"
            case memberName = "member_name"
            case memberId = "member_id"
            case xUserHandle = "twitter_user_handle"
        }
    }
}
