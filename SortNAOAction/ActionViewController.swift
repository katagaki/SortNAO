//
//  ActionViewController.swift
//  SortNAOAction
//
//  Created by Claude on 2026/02/26.
//

import KeychainAccess
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

// swiftlint:disable type_body_length file_length
class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contentVC = ActionContentViewController()
        contentVC.extensionContextWrapper = self.extensionContext
        
        let nav = UINavigationController(rootViewController: contentVC)
        addChild(nav)
        view.addSubview(nav.view)
        nav.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nav.view.topAnchor.constraint(equalTo: view.topAnchor),
            nav.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            nav.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nav.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        nav.didMove(toParent: self)
    }
}

class ActionContentViewController: UIViewController {
    var extensionContextWrapper: NSExtensionContext?

    private let keychain = Keychain(service: "com.tsubuzaki.SortNAO")
    private let keychainAPIKeyKey = "SauceNAOAPIKey"
    private let endpoint = URL(string: "https://saucenao.com/search.php")!

    private var imageView: UIImageView!
    private var resultsStack: UIStackView!
    private var activityIndicator: UIActivityIndicatorView!
    private var statusLabel: UILabel!
    private var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImageFromExtensionContext()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "SortNAO"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(done)
        )

        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        contentView.addSubview(imageView)

        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        contentView.addSubview(activityIndicator)

        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.font = .preferredFont(forTextStyle: .headline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        contentView.addSubview(statusLabel)

        resultsStack = UIStackView()
        resultsStack.translatesAutoresizingMaskIntoConstraints = false
        resultsStack.axis = .vertical
        resultsStack.spacing = 12
        resultsStack.alignment = .fill
        contentView.addSubview(resultsStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -32),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 300),

            activityIndicator.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            resultsStack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            resultsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            resultsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            resultsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    private func loadImageFromExtensionContext() {
        guard let extensionItems = extensionContextWrapper?.inputItems as? [NSExtensionItem] else {
            showError("No input items found.")
            return
        }

        for extensionItem in extensionItems {
            guard let attachments = extensionItem.attachments else { continue }
            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    attachment.loadItem(
                        forTypeIdentifier: UTType.image.identifier,
                        options: nil
                    ) { [weak self] data, _ in
                        let sendableData = data as? Data
                        let sendableURL = data as? URL
                        let sendableImage = data as? UIImage
                        DispatchQueue.main.async {
                            if let url = sendableURL,
                               let imageData = try? Data(contentsOf: url) {
                                self?.handleLoadedImageData(imageData)
                            } else if let imageData = sendableData {
                                self?.handleLoadedImageData(imageData)
                            } else if let image = sendableImage {
                                self?.handleLoadedUIImage(image)
                            } else {
                                self?.showError("Could not load image.")
                            }
                        }
                    }
                    return
                }
            }
        }

        showError("No image found in the shared content.")
    }

    private func handleLoadedImageData(_ data: Data) {
        guard let image = UIImage(data: data) else {
            showError("Could not load image.")
            return
        }
        imageView.image = image
        searchSauce(for: image)
    }

    private func handleLoadedUIImage(_ image: UIImage) {
        imageView.image = image
        searchSauce(for: image)
    }

    private func searchSauce(for image: UIImage) {
        guard let apiKey = try? keychain.get(keychainAPIKeyKey) else {
            showError("No SauceNAO API key set. Please set your API key in the SortNAO app first.")
            return
        }

        activityIndicator.startAnimating()
        statusLabel.text = NSLocalizedString("Action.Searching", comment: "")

        Task {
            do {
                let results = try await performSearch(image: image, apiKey: apiKey)
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    displayResults(results)
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    showError("Search failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func performSearch(image: UIImage, apiKey: String) async throws -> SearchResponse {
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

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response
    }

    private func displayResults(_ response: SearchResponse) {
        let results = response.results.sorted {
            (Double($0.header.similarity) ?? 0) > (Double($1.header.similarity) ?? 0)
        }

        if results.isEmpty {
            statusLabel.text = NSLocalizedString("Action.NoResults", comment: "")
            return
        }

        statusLabel.text = NSLocalizedString("Action.ResultsFound", comment: "")

        for result in results {
            let similarity = result.header.similarity
            let card = createResultCard(result: result, similarity: similarity)
            resultsStack.addArrangedSubview(card)
        }
    }

    private func createResultCard(result: SearchResult, similarity: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])

        let similarityLabel = UILabel()
        similarityLabel.font = .preferredFont(forTextStyle: .headline)
        similarityLabel.text = "\(similarity)% match"
        similarityLabel.textColor = (Double(similarity) ?? 0) >= 65.0 ? .systemGreen : .systemOrange
        stack.addArrangedSubview(similarityLabel)

        let sourceName = result.header.indexName
        let sourceLabel = UILabel()
        sourceLabel.font = .preferredFont(forTextStyle: .subheadline)
        sourceLabel.textColor = .secondaryLabel
        sourceLabel.text = sourceName
        sourceLabel.numberOfLines = 0
        stack.addArrangedSubview(sourceLabel)

        if let material = result.data.material, !material.isEmpty {
            let materialLabel = UILabel()
            materialLabel.font = .preferredFont(forTextStyle: .body)
            materialLabel.text = "Material: \(material)"
            materialLabel.numberOfLines = 0
            stack.addArrangedSubview(materialLabel)
        }

        if let characters = result.data.characters, !characters.isEmpty {
            let charsLabel = UILabel()
            charsLabel.font = .preferredFont(forTextStyle: .body)
            charsLabel.text = "Characters: \(characters)"
            charsLabel.numberOfLines = 0
            stack.addArrangedSubview(charsLabel)
        }

        if let memberName = result.data.memberName {
            let artistLabel = UILabel()
            artistLabel.font = .preferredFont(forTextStyle: .body)
            artistLabel.text = "Artist: \(memberName)"
            artistLabel.numberOfLines = 0
            stack.addArrangedSubview(artistLabel)
        }

        if let creator = result.data.creator, !creator.isEmpty {
            let creatorLabel = UILabel()
            creatorLabel.font = .preferredFont(forTextStyle: .body)
            creatorLabel.text = "Creator: \(creator)"
            creatorLabel.numberOfLines = 0
            stack.addArrangedSubview(creatorLabel)
        }

        if let xHandle = result.data.xUserHandle {
            let handleLabel = UILabel()
            handleLabel.font = .preferredFont(forTextStyle: .body)
            handleLabel.text = "X: @\(xHandle)"
            handleLabel.numberOfLines = 0
            stack.addArrangedSubview(handleLabel)
        }

        if let urls = result.data.externalURLs, !urls.isEmpty {
            for urlString in urls {
                let linkButton = UIButton(type: .system)
                linkButton.setTitle(urlString, for: .normal)
                linkButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
                linkButton.titleLabel?.numberOfLines = 1
                linkButton.titleLabel?.lineBreakMode = .byTruncatingTail
                linkButton.contentHorizontalAlignment = .leading
                linkButton.tag = urlString.hashValue
                linkButton.accessibilityValue = urlString
                linkButton.addTarget(self, action: #selector(openURL(_:)), for: .touchUpInside)
                stack.addArrangedSubview(linkButton)
            }
        }

        return card
    }

    @objc private func openURL(_ sender: UIButton) {
        guard let urlString = sender.accessibilityValue,
              let url = URL(string: urlString) else { return }
        extensionContextWrapper?.open(url)
    }

    private func showError(_ message: String) {
        activityIndicator?.stopAnimating()
        statusLabel?.text = message
    }

    @objc func done() {
        extensionContextWrapper?.completeRequest(returningItems: nil)
    }
}

// MARK: - Search Models

extension ActionContentViewController {
    enum SearchError: Error {
        case invalidImage
        case invalidURL
    }

    struct SearchResponse: Codable {
        var results: [SearchResult]
    }

    struct SearchResult: Codable {
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
}
// swiftlint:enable type_body_length file_length
