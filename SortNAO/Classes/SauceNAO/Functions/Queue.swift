//
//  Queue.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import Foundation
import SwiftUICore
import UIKit

extension SauceNAO {
    public func add(_ imageURL: URL) async {
        self.thumbnails[imageURL] = await self.thumbnail(imageURL)
        withAnimation {
            self.queue.append(imageURL)
        }
    }

    public func remove(_ imageURL: URL) {
        withAnimation {
            self.queue.removeAll(where: { $0 == imageURL })
        }
        self.thumbnails.removeValue(forKey: imageURL)
    }

    public func requeueFailed() {
        withAnimation {
            self.queue.append(contentsOf: self.failed)
            self.failed.removeAll()
        }
    }

    public func clear() {
        withAnimation {
            self.queue.removeAll()
            self.failed.removeAll()
            self.succeeded.removeAll()
            self.categorized.removeAll()
            self.noMatches.removeAll()
        }
    }
}
