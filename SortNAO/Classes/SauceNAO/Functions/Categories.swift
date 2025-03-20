//
//  Categories.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import Foundation

extension SauceNAO {
    func urls(in category: Category) -> [URL] {
        self.categorized[category] ?? []
    }

    func categorize(_ imageURL: URL, result: Response.Result) {
        let pixivId = result.data.pixivId
        let category = Category(
            material: result.data.material,
            characters: result.data.characters,
            pixivId: pixivId != nil ? String(pixivId!) : nil,
            memberName: result.data.memberName,
            xUserHandle: result.data.xUserHandle
        )
        self.categorized[category, default: []].append(imageURL)
    }
}
