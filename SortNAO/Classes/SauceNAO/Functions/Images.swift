//
//  Images.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import Foundation
import UIKit

extension SauceNAO {
    @MainActor
    internal func thumbnail(_ imageURL: URL) async -> UIImage? {
        if let uiImage = thumbnails[imageURL] {
            return uiImage
        } else {
            guard let imageData = try? Data(contentsOf: imageURL) else { return nil }
            guard let uiImage = UIImage(data: imageData) else { return nil }
            guard let thumbnailImage = await uiImage.byPreparingThumbnail(
                ofSize: CGSize(width: 200.0, height: 200.0)
            ) else { return nil }
            self.thumbnails[imageURL] = thumbnailImage
            return thumbnailImage
        }
    }
}
