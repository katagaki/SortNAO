//
//  Search.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import Foundation
import SwiftUICore

extension SauceNAO {
    // swiftlint:disable large_tuple
    public func searchAll(
        in sources: [Source] = [.danbooru, .gelbooru],
        delay: Int = 0
    ) -> AsyncStream<(URL, ResultType, Response.Result?)> {
        AsyncStream { continuation in
            Task {
                let imageURLs: [URL] = self.queue
                for imageURL in imageURLs {
                    do {
                        let response = try await self.search(in: sources, imageURL)

                        var results = response.results
                        if results.count > 1 {
                            results.sort { $0.header.similarityValue() > $1.header.similarityValue() }
                        }

                        if let result = results.first, result.header.similarityValue() >= 65.0 {
                            withAnimation {
                                self.queue.removeAll(where: { $0 == imageURL })
                                self.succeeded[imageURL] = result
                                self.categorize(imageURL, result: result)
                            }
                            continuation.yield((imageURL, .succeeded, result))
                        } else {
                            withAnimation {
                                self.queue.removeAll(where: { $0 == imageURL })
                                self.noMatches[imageURL] = response
                            }
                            continuation.yield((imageURL, .noMatches, nil))
                        }
                    } catch {
                        debugPrint(error, error.localizedDescription)
                        withAnimation {
                            self.queue.removeAll(where: { $0 == imageURL })
                            self.failed.append(imageURL)
                        }
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
    // swiftlint:enable large_tuple

    public func search(in sources: [Source], _ imageURL: URL) async throws -> Response {
        guard let apiKey = self.apiKey else {
            throw APIError.noAPIKeySpecified
        }

        let imageData = try Data(contentsOf: imageURL)
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
        let sourceURLQueryItems = sources.compactMap({
            URLQueryItem(name: "dbs[]", value: String($0.rawValue))
        })
        var components = URLComponents(string: endpoint.absoluteString)!
        components.queryItems = sourceURLQueryItems + [
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
}
