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
    @ObservationIgnored let fileManager = FileManager.default
    @ObservationIgnored let keychain = Keychain(service: "com.tsubuzaki.SortNAO")
    @ObservationIgnored let keychainAPIKeyKey: String = "SauceNAOAPIKey"

    @ObservationIgnored internal let supportedExtensions = ["jpg", "jpeg", "png"]
    @ObservationIgnored internal let endpoint = URL(string: "https://saucenao.com/search.php")!
    internal var apiKey: String?
    internal var threshold: Float

    @ObservationIgnored internal var thumbnails: [URL: UIImage] = [:]

    public var queue: [URL] = []
    public var failed: [URL] = []
    public var succeeded: [URL: Response.Result] = [:]
    public var categorized: [Category: [URL]] = [:]
    public var noMatches: [URL: Response] = [:]

    public var categories: [Category] { Array(self.categorized.keys).sorted(by: <) }
    public var noMatchesURLs: [URL] { Array(self.noMatches.keys) }

    public var isReady: Bool { !queue.isEmpty && apiKey != nil }
    public var isAPIKeySet: Bool { apiKey != nil }

    public init(threshold: Float = 65.0) {
        self.apiKey = try? keychain.get(keychainAPIKeyKey)
        self.threshold = threshold
    }

    internal func boundary() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let nonce = String((0..<16).map { _ in characters.randomElement()! })
        return "----------SortNAOBoundary\(nonce)"
    }
}
