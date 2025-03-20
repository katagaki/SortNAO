//
//  Category.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import SwiftUICore

extension SauceNAO {
    struct Category: Hashable {
        var source: Source
        var material: String?
        var characters: [String]
        var pixivId: Int?
        var memberName: String?
        var xUserHandle: String?

        init(result: Response.Result) throws {
            if let source = Source(rawValue: result.header.indexId) {
                self.source = source
                self.material = result.data.material
                self.characters = (
                    (result.data.characters?.components(separatedBy: [","]) ?? [])
                        .map({ $0.trimmingCharacters(in: .whitespaces) })
                )
                self.pixivId = result.data.pixivId
                self.memberName = result.data.memberName
                self.xUserHandle = result.data.xUserHandle
            } else {
                throw APIError.unsupportedSource(message: String(result.header.indexId))
            }
        }

        func displayName() -> AttributedString? {
            var displayName: String?
            switch source {
            case .danbooru, .gelbooru:
                if let material {
                    displayName = material +
                    (material != "" && characters.count != 0 ? "  - " : "") +
                    characters.joined(separator: ", ")
                }
            case .pixiv:
                if let pixivId, let memberName {
                    displayName = """
                       \(memberName) - [\(pixivId)](https://www.pixiv.net/artworks/\(pixivId))
                       """
                }
            case .elonX:
                if let xUserHandle {
                    displayName = """
                           [@\(xUserHandle)](https://x.com/\(xUserHandle))
                           """
                }
            default: break
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
