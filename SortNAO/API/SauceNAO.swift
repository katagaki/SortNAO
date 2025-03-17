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
    private var threshold: Float

    public var queue: [URL: Data] = [:]
    public var failed: [URL: Data] = [:]
    public var succeeded: [URL: (Data, Response)] = [:]
    public var noMatches: [URL: (Data, Response)] = [:]

    public var isReady: Bool { !queue.isEmpty && apiKey != nil }
    public var isAPIKeySet: Bool { apiKey != nil }

    public init(threshold: Float = 65.0) {
        self.apiKey = try? keychain.get(keychainAPIKeyKey)
        self.threshold = threshold
    }

    public func queue(_ imageURL: URL) {
        do {
            self.queue[imageURL] = try Data(contentsOf: imageURL)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    public func remove(_ imageURL: URL) { self.queue.removeValue(forKey: imageURL) }

    public func clear() {
        self.queue.removeAll()
        self.failed.removeAll()
        self.succeeded.removeAll()
    }

    public func setAPIKey(_ apiKey: String) {
        try? keychain.set(apiKey, key: keychainAPIKeyKey)
        self.apiKey = apiKey
    }

    public func resetAPIKey() {
        try? keychain.remove(keychainAPIKeyKey)
        self.apiKey = nil
    }

    public func searchAll(in sources: [Source], delay: Int = 0) -> AsyncStream<(URL, ResultType, Response.Result?)> {
        AsyncStream { continuation in
            Task {
                let imageURLs: [URL] = Array(queue.keys).sorted(by: { $0.absoluteString < $1.absoluteString })
                for imageURL in imageURLs {
                    guard let imageData = self.queue[imageURL] else { continue }

                    do {
                        let response = try await self.search(in: sources, imageURL, imageData: imageData)

                        var results = response.results
                        if results.count > 1 {
                            results.sort { $0.header.similarityValue() > $1.header.similarityValue() }
                        }

                        if let result = results.first, result.header.similarityValue() >= 65.0 {
                            self.succeeded[imageURL] = (imageData, response)
                            self.queue.removeValue(forKey: imageURL)
                            continuation.yield((imageURL, .succeeded, result))
                        } else {
                            self.noMatches[imageURL] = (imageData, response)
                            self.queue.removeValue(forKey: imageURL)
                            continuation.yield((imageURL, .noMatches, nil))
                        }

                    } catch {
                        debugPrint(error, error.localizedDescription)
                        self.failed[imageURL] = imageData
                        self.queue.removeValue(forKey: imageURL)
                        continuation.yield((imageURL, .failed, nil))
                    }

                    if delay > 0 {
                        try? await Task.sleep(for: .seconds(delay))
                    }
                }
                continuation.finish()
            }
        }
    }

    private func search(in sources: [Source], _ imageURL: URL, imageData: Data) async throws -> Response {
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
}
