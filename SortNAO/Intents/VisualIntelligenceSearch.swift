//
//  VisualIntelligenceSearch.swift
//  SortNAO
//
//  Created by Claude on 2026/02/26.
//

import AppIntents
import CoreImage
import KeychainAccess
import UIKit
import VisualIntelligence

// MARK: - Sauce Entity

@available(iOS 26.0, *)
struct SauceEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Entity.Sauce.Name"),
            numericFormat: "\(placeholder: .int) results"
        )
    }

    static let defaultQuery = SauceEntityQuery()

    var id: String
    var similarity: String
    var sourceName: String
    var detailText: String

    @Property(title: "Character")
    var character: String?

    @Property(title: "Artist")
    var artist: String?

    @Property(title: "Source Link")
    var sourceURL: URL?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(similarity)% match",
            subtitle: "\(detailText)",
            image: .init(systemName: "sparkle.magnifyingglass")
        )
    }

    var appLinkURL: URL? { sourceURL }

    init(
        id: String,
        similarity: String,
        sourceName: String,
        detailText: String,
        character: String? = nil,
        artist: String? = nil,
        sourceURL: URL? = nil
    ) {
        self.id = id
        self.similarity = similarity
        self.sourceName = sourceName
        self.detailText = detailText
        self.character = character
        self.artist = artist
        self.sourceURL = sourceURL
    }
}

// MARK: - Entity Query

@available(iOS 26.0, *)
struct SauceEntityQuery: EntityQuery {
    func entities(for identifiers: [SauceEntity.ID]) async throws -> [SauceEntity] {
        []
    }
}

// MARK: - Visual Intelligence Search Query

@available(iOS 26.0, *)
struct SauceVisualSearchQuery: IntentValueQuery {
    // swiftlint:disable function_body_length
    func values(for input: SemanticContentDescriptor) async throws -> [SauceEntity] {
        guard let pixelBuffer = input.pixelBuffer else {
            return []
        }

        let keychain = Keychain(service: "com.tsubuzaki.SortNAO")
        guard let apiKey = try? keychain.get("SauceNAOAPIKey") else {
            return []
        }

        // Convert pixel buffer to JPEG inside withUnsafeBuffer for memory safety
        guard let jpegData = pixelBuffer.withUnsafeBuffer({ cvBuffer -> Data? in
            let ciImage = CIImage(cvPixelBuffer: cvBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.9)
        }) else {
            return []
        }

        // Build API request
        let boundary = "----------SortNAOBoundary\(UUID().uuidString.prefix(16))"
        var components = URLComponents(string: "https://saucenao.com/search.php")!
        components.queryItems = [
            URLQueryItem(name: "output_type", value: "2"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "numres", value: "5")
        ]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        // swiftlint:disable non_optional_string_data_conversion
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(jpegData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        // swiftlint:enable non_optional_string_data_conversion

        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SauceResponse.self, from: data)

        let sortedResults = response.results.sorted {
            (Double($0.header.similarity) ?? 0) > (Double($1.header.similarity) ?? 0)
        }

        return sortedResults.prefix(10).enumerated().compactMap { index, result -> SauceEntity? in
            let similarity = result.header.similarity
            guard (Double(similarity) ?? 0) >= 50.0 else { return nil }

            var details: [String] = []
            if let material = result.data.material, !material.isEmpty {
                details.append(material)
            }
            if let characters = result.data.characters, !characters.isEmpty {
                details.append(characters)
            }
            if let memberName = result.data.memberName {
                details.append(memberName)
            }
            if let creator = result.data.creator, !creator.isEmpty, result.data.memberName == nil {
                details.append(creator)
            }
            if let xHandle = result.data.xUserHandle {
                details.append("@\(xHandle)")
            }

            let detailText = details.isEmpty
                ? result.header.indexName
                : details.joined(separator: " · ")

            let artist = result.data.memberName ?? result.data.creator
            let sourceURL = result.data.externalURLs?.first.flatMap { URL(string: $0) }

            return SauceEntity(
                id: "\(index)-\(similarity)",
                similarity: similarity,
                sourceName: result.header.indexName,
                detailText: detailText,
                character: result.data.characters,
                artist: artist,
                sourceURL: sourceURL
            )
        }
    }
    // swiftlint:enable function_body_length
}

// MARK: - Open Sauce Intent

@available(iOS 26.0, *)
struct OpenSauceIntent: OpenIntent {
    static let title: LocalizedStringResource = "Intent.OpenSauce.Title"

    @Parameter(title: "Shared.SourceResult")
    var target: SauceEntity
}

// MARK: - View More Sauces Intent

@available(iOS 26.0, *)
@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct ViewMoreSaucesIntent: AppIntent {
    static let title: LocalizedStringResource = "Intent.ViewMoreSauces.Title"

    @Parameter(title: "Shared.SemanticContent")
    var semanticContent: SemanticContentDescriptor

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
