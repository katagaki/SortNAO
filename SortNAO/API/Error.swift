//
//  Error.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/17.
//

extension SauceNAO {
    enum APIError: Error {
        case noAPIKeySpecified
        case invalidURL(message: String)
        case invalidFileType(message: String)
    }
}
