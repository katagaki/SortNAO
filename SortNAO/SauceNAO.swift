//
//  API.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import KeychainAccess
import SwiftUI
import UIKit

@Observable
class SauceNAO {
    @ObservationIgnored let keychain = Keychain(service: "com.tsubuzaki.SortNAO")
    @ObservationIgnored let keychainAPIKeyKey: String = "SauceNAOAPIKey"

    @ObservationIgnored private let endpoint = URL(string: "https://saucenao.com/search.php")!
    private var apiKey: String?

    public var queue: [URL: Data] = [:]
    public var results: [URL: Response] = [:]

    public var isReady: Bool { !queue.isEmpty && apiKey != nil }
    public var isAPIKeySet: Bool { apiKey != nil }

    public init() {
        self.apiKey = try? keychain.get(keychainAPIKeyKey)
    }

    public func queue(_ imageURL: URL) {
        do {
            self.queue[imageURL] = try Data(contentsOf: imageURL)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    public func remove(_ imageURL: URL) { self.queue.removeValue(forKey: imageURL) }

    public func setAPIKey(_ apiKey: String) {
        try? keychain.set(apiKey, key: keychainAPIKeyKey)
        self.apiKey = apiKey
    }

    public func resetAPIKey() {
        try? keychain.remove(keychainAPIKeyKey)
        self.apiKey = nil
    }

    public func booruMaterialKeys() {

    }

    public func searchQueue() async {
        let imageURLs: [URL] = Array(queue.keys).sorted(by: { $0.absoluteString < $1.absoluteString })
        for imageURL in imageURLs {
            guard let imageData = self.queue[imageURL] else { continue }
            do {
                let results = try await self.search(imageURL, imageData: imageData)
                self.results[imageURL] = results
                self.queue.removeValue(forKey: imageURL)
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }

    private func search(_ imageURL: URL, imageData: Data) async throws -> Response {
        guard let apiKey else {
            throw APIError.noAPIKeySpecified
        }

        let fileExtension = imageURL.pathExtension.lowercased()
        var mimetype: String?

        switch fileExtension {
        case "jpg", "jpeg": mimetype = "image/jpeg"
        case "png": mimetype = "image/png"
        default: break
        }

        guard let mimetype else {
            throw APIError.invalidFileType(message: fileExtension)
        }

        let requestBoundary = self.boundary()
        var components = URLComponents(string: endpoint.absoluteString)!
        components.queryItems = [
            URLQueryItem(name: "dbs[]", value: "5"), // pixiv
            URLQueryItem(name: "dbs[]", value: "9"), // danbooru
            URLQueryItem(name: "dbs[]", value: "25"), // gelbooru
            URLQueryItem(name: "dbs[]", value: "41"), // X
            URLQueryItem(name: "output_type", value: "2"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "numres", value: "3")
        ]

        guard let url = components.url else {
            throw APIError.invalidURL(message: components.path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(requestBoundary)", forHTTPHeaderField: "Content-Type")

        // swiftlint:disable non_optional_string_data_conversion line_length
        var body: Data = Data()
        body.append("--\(requestBoundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.\(fileExtension)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimetype)\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(requestBoundary)--\r\n".data(using: .utf8)!)
        // swiftlint:enable non_optional_string_data_conversion line_length

        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)
        let results = try JSONDecoder().decode(Response.self, from: data)

        return results
    }

    private func boundary() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let nonce = String((0..<16).map { _ in characters.randomElement()! })
        return "----------SortNAOBoundary\(nonce)"
    }

    enum APIError: Error {
        case noAPIKeySpecified
        case invalidURL(message: String)
        case invalidFileType(message: String)
    }

    // swiftlint:disable nesting
    struct Response: Codable {
        var header: Header
        var results: [Result]

        struct Header: Codable {
            var userId: String
            var accountType: String
            var shortLimit: String
            var longLimit: String
            var longRemaining: Int
            var shortRemaining: Int
            var status: Int
            var resultsRequested: Int
            var index: [String: Index]
            var searchDepth: String
            var minimumSimilarity: Double
            var queryImageDisplay: String
            var queryImage: String
            var resultsReturned: Int

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case accountType = "account_type"
                case shortLimit = "short_limit"
                case longLimit = "long_limit"
                case longRemaining = "long_remaining"
                case shortRemaining = "short_remaining"
                case status = "status"
                case resultsRequested = "results_requested"
                case index = "index"
                case searchDepth = "search_depth"
                case minimumSimilarity = "minimum_similarity"
                case queryImageDisplay = "query_image_display"
                case queryImage = "query_image"
                case resultsReturned = "results_returned"
            }

            struct Index: Codable {
                var status: Int
                var parentId: Int
                var id: Int
                var results: Int

                enum CodingKeys: String, CodingKey {
                    case status = "status"
                    case parentId = "parent_id"
                    case id = "id"
                    case results = "results"
                }
            }
        }

        struct Result: Codable {
            var header: Header
            var data: Data

            struct Header: Codable {
                var similarity: String
                var thumbnail: String
                var indexId: Int
                var indexName: String
                var dupes: Int
                var hidden: Int

                enum CodingKeys: String, CodingKey {
                    case similarity = "similarity"
                    case thumbnail = "thumbnail"
                    case indexId = "index_id"
                    case indexName = "index_name"
                    case dupes = "dupes"
                    case hidden = "hidden"
                }
            }

            struct Data: Codable {
                var externalURLs: [String]

                // Danbooru/Gelbooru
                var danbooruId: Int?
                var gelbooruId: Int?
                var creator: String?
                var material: String?
                var characters: String?
                var source: String?

                // pixiv
                var title: String?
                var pixivId: Int?
                var memberName: String?
                var memberId: Int?

                // X
                var createdAt: String?
                var postId: String?
                var xUserId: String?
                var xUserHandle: String?

                enum CodingKeys: String, CodingKey {
                    case externalURLs = "ext_urls"
                    case danbooruId = "danbooru_id"
                    case gelbooruId = "gelbooru_id"
                    case creator = "creator"
                    case material = "material"
                    case characters = "characters"
                    case source = "source"
                    case title = "title"
                    case pixivId = "pixiv_id"
                    case memberName = "member_name"
                    case memberId = "member_id"
                    case createdAt = "created_at"
                    case postId = "tweet_id"
                    case xUserId = "twitter_user_id"
                    case xUserHandle = "twitter_user_handle"
                }
            }
        }
    }
    // swiftlint:enable nesting
}
