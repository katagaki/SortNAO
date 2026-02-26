//
//  SearchSauceIntent.swift
//  SortNAO
//
//  Created by Claude on 2026/02/26.
//

import AppIntents
import KeychainAccess
import UIKit

@available(iOS 18.0, *)
struct SearchSauceIntent: AppIntent {
    static let title: LocalizedStringResource = "Intent.SearchSauce.Title"
    static let description: IntentDescription = "Intent.SearchSauce.Description"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Shared.Image")
    var image: IntentFile

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let keychain = Keychain(service: "com.tsubuzaki.SortNAO")
        guard let apiKey = try? keychain.get("SauceNAOAPIKey") else {
            return .result(
                value: "No API key set",
                dialog: "Error.NoAPIKey"
            )
        }

        let imageData = image.data
        guard let uiImage = UIImage(data: imageData),
              let jpegData = uiImage.jpegData(compressionQuality: 0.9) else {
            return .result(
                value: "Invalid image",
                dialog: "Error.ImageProcessing"
            )
        }

        let boundary = "----------SortNAOBoundary\(UUID().uuidString.prefix(16))"
        var components = URLComponents(string: "https://saucenao.com/search.php")!
        components.queryItems = [
            URLQueryItem(name: "output_type", value: "2"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "numres", value: "3")
        ]

        guard let url = components.url else {
            return .result(value: "Error", dialog: "Intent.SearchSauce.Error.URLConstruction")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        // swiftlint:disable non_optional_string_data_conversion line_length
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(jpegData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        // swiftlint:enable non_optional_string_data_conversion line_length

        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SauceResponse.self, from: data)

        let sortedResults = response.results.sorted {
            (Double($0.header.similarity) ?? 0) > (Double($1.header.similarity) ?? 0)
        }

        guard let topResult = sortedResults.first else {
            return .result(value: "No matches", dialog: "Search.NoSourcesFound")
        }

        let similarity = topResult.header.similarity
        var resultText = "\(similarity)% match"

        if let material = topResult.data.material, !material.isEmpty {
            resultText += "\nMaterial: \(material)"
        }
        if let characters = topResult.data.characters, !characters.isEmpty {
            resultText += "\nCharacters: \(characters)"
        }
        if let memberName = topResult.data.memberName {
            resultText += "\nArtist: \(memberName)"
        }
        if let creator = topResult.data.creator, !creator.isEmpty {
            resultText += "\nCreator: \(creator)"
        }
        if let xHandle = topResult.data.xUserHandle {
            resultText += "\nX: @\(xHandle)"
        }
        if let urls = topResult.data.externalURLs, let firstURL = urls.first {
            resultText += "\n\(firstURL)"
        }

        return .result(
            value: resultText,
            dialog: "Search.MatchFound.\(similarity)"
        )
    }
}

@available(iOS 18.0, *)
struct SauceResponse: Codable {
    var results: [SauceResult]
}

@available(iOS 18.0, *)
struct SauceResult: Codable {
    var header: SauceResultHeader
    var data: SauceResultData
}

@available(iOS 18.0, *)
struct SauceResultHeader: Codable {
    var similarity: String
    var indexId: Int
    var indexName: String

    enum CodingKeys: String, CodingKey {
        case similarity
        case indexId = "index_id"
        case indexName = "index_name"
    }
}

@available(iOS 18.0, *)
struct SauceResultData: Codable {
    var externalURLs: [String]?
    var creator: String?
    var material: String?
    var characters: String?
    var memberName: String?
    var xUserHandle: String?

    enum CodingKeys: String, CodingKey {
        case externalURLs = "ext_urls"
        case creator
        case material
        case characters
        case memberName = "member_name"
        case xUserHandle = "twitter_user_handle"
    }
}
