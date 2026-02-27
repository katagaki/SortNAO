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
    var thumbnailData: Data?

    @Property(title: "Character")
    var character: String?

    @Property(title: "Artist")
    var artist: String?

    @Property(title: "Source Link")
    var sourceURL: URL?

    var displayRepresentation: DisplayRepresentation {
        let title = character ?? sourceName

        var subtitleParts: [String] = [sourceName]
        if let artist, !artist.isEmpty {
            subtitleParts.append(artist)
        }
        subtitleParts.append(String(format: NSLocalizedString("Action.Match.%@", comment: ""), similarity))

        let image: DisplayRepresentation.Image = if let thumbnailData {
            .init(data: thumbnailData)
        } else {
            .init(systemName: "sparkle.magnifyingglass")
        }

        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitleParts.joined(separator: " · "))",
            image: image
        )
    }

    var appLinkURL: URL? {
        guard let sourceURL else { return nil }
        var components = URLComponents()
        components.scheme = "nao"
        components.host = "openSauce"
        components.queryItems = [URLQueryItem(name: "url", value: sourceURL.absoluteString)]
        return components.url
    }

    init(
        id: String,
        similarity: String,
        sourceName: String,
        thumbnailData: Data? = nil,
        character: String? = nil,
        artist: String? = nil,
        sourceURL: URL? = nil
    ) {
        self.id = id
        self.similarity = similarity
        self.sourceName = sourceName
        self.thumbnailData = thumbnailData
        self.character = character
        self.artist = artist
        self.sourceURL = sourceURL
    }
}

// MARK: - Entity Cache

@available(iOS 26.0, *)
actor SauceEntityCache {
    static let shared = SauceEntityCache()
    private var cache: [String: SauceEntity] = [:]

    func store(_ entities: [SauceEntity]) {
        for entity in entities {
            cache[entity.id] = entity
        }
    }

    func fetch(ids: [String]) -> [SauceEntity] {
        ids.compactMap { cache[$0] }
    }
}

// MARK: - Entity Query

@available(iOS 26.0, *)
struct SauceEntityQuery: EntityQuery {
    func entities(for identifiers: [SauceEntity.ID]) async throws -> [SauceEntity] {
        return await SauceEntityCache.shared.fetch(ids: identifiers)
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

        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return [] }
        guard let response = try? JSONDecoder().decode(SauceResponse.self, from: data) else { return [] }

        let sortedResults = response.results.sorted {
            (Double($0.header.similarity) ?? 0) > (Double($1.header.similarity) ?? 0)
        }

        var entities: [SauceEntity] = []
        for (index, result) in sortedResults.prefix(10).enumerated() {
            let similarity = result.header.similarity
            guard (Double(similarity) ?? 0) >= 50.0 else { continue }

            let artist = result.data.memberName ?? result.data.creator
            let sourceURL = result.data.externalURLs?.first.flatMap { URL(string: $0) }

            var thumbnailData: Data?
            if let thumbnailURL = URL(string: result.header.thumbnail) {
                thumbnailData = try? await URLSession.shared.data(from: thumbnailURL).0
            }

            entities.append(SauceEntity(
                id: "\(index)-\(similarity)",
                similarity: similarity,
                sourceName: result.header.indexName,
                thumbnailData: thumbnailData,
                character: result.data.characters,
                artist: artist,
                sourceURL: sourceURL
            ))
        }

        guard !entities.isEmpty else {
            throw SortNAOIntentError.noResults
        }

        await SauceEntityCache.shared.store(entities)
        return entities
    }
    // swiftlint:enable function_body_length
}

// MARK: - Open Sauce Intent

@available(iOS 26.0, *)
struct OpenSauceIntent: OpenIntent {
    static let title: LocalizedStringResource = "Intent.OpenSauce.Title"

    @Parameter(title: "Shared.SourceResult")
    var target: SauceEntity

    func perform() async throws -> some IntentResult {
        guard let sourceURL = target.sourceURL else {
            return .result()
        }
        await MainActor.run {
            UIApplication.shared.open(sourceURL)
        }
        return .result()
    }
}
