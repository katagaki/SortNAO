//
//  Category.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import SwiftUICore

extension SauceNAO {
    struct Category: Hashable {
        var material: String?
        var characters: [String]
        var pixivId: String?
        var memberName: String?
        var xUserHandle: String?

        init(
            material: String? = nil,
            characters: String? = nil,
            pixivId: String? = nil,
            memberName: String? = nil,
            xUserHandle: String? = nil
        ) {
            self.material = material
            self.characters = (
                (characters?.components(separatedBy: [","]) ?? [])
                    .map({ $0.trimmingCharacters(in: .whitespaces) })
            )
            self.pixivId = pixivId
            self.memberName = memberName
            self.xUserHandle = xUserHandle
        }

        func displayName() -> AttributedString? {
            var displayName: String?
            if let material {
                displayName = material +
                (material != "" && characters.count != 0 ? "  - " : "") +
                characters.joined(separator: ", ")
            } else if let pixivId, let memberName {
                displayName = """
                       \(memberName) - [\(pixivId)](https://www.pixiv.net/artworks/\(pixivId))
                       """
            } else if let xUserHandle {
                displayName = """
                       [@\(xUserHandle)](https://x.com/\(xUserHandle))
                       """
            }
            if let displayName {
                return try? AttributedString(markdown: displayName)
            } else {
                return nil
            }
        }

        static func < (lhs: Category, rhs: Category) -> Bool {
            return lhs.displayName()?.description ?? "" < rhs.displayName()?.description ?? ""
        }
    }
}
