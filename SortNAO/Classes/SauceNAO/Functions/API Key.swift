//
//  API Key.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import Foundation

extension SauceNAO {
    public func setAPIKey(_ apiKey: String) {
        try? keychain.set(apiKey, key: keychainAPIKeyKey)
        self.apiKey = apiKey
    }

    public func resetAPIKey() {
        try? keychain.remove(keychainAPIKeyKey)
        self.apiKey = nil
    }
}
