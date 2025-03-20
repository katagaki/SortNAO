//
//  Categories.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import Foundation

extension SauceNAO {
    func categorize(_ imageURL: URL, result: Response.Result) {
        let material = result.data.material
        let characters = result.data.characters
        let pixivId = result.data.pixivId
        let xUserHandle = result.data.xUserHandle
        let category: String? = switch true {
        case material == "" && characters != nil: characters!
        case material != nil && characters != nil: "\(material!) - \(characters!)"
        case pixivId != nil: "Pixiv: \(pixivId!)"
        case xUserHandle != nil: "X (Twitter): \(xUserHandle!)"
        default: nil
        }
        guard let category else { return }
        self.categorized[category, default: []].append(imageURL)
    }
}
