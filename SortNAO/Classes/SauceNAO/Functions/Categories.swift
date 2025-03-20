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
        if let category = try? Category(result: result) {
            self.categorized[category, default: []].append(imageURL)
        }
    }
}
