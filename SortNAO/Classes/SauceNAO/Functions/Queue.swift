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
    private func supports(_ fileURL: URL) -> Bool {
        let attributes = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
        if attributes?.isRegularFile ?? false {
            let fileExtension = fileURL.pathExtension.lowercased()
            return self.supportedExtensions.contains(fileExtension)
        } else {
            return false
        }
    }

    public func add(folder folderURL: URL) async {
        if folderURL.startAccessingSecurityScopedResource() {
            guard let enumerator = FileManager.default.enumerator(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                return
            }
            for case let fileURL as URL in enumerator {
                await self.add(file: fileURL)
            }
        }
    }

    public func add(file imageURL: URL) async {
        if self.supports(imageURL) {
            if !self.thumbnails.keys.contains(imageURL) {
                self.thumbnails[imageURL] = await self.thumbnail(imageURL)
            }
            if !self.queue.contains(imageURL) {
                withAnimation {
                    self.queue.append(imageURL)
                }
            }
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
            for failedImageURL in self.failed where !self.queue.contains(failedImageURL) {
                self.queue.append(failedImageURL)
            }
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
            self.thumbnails.removeAll()
        }
    }
}
