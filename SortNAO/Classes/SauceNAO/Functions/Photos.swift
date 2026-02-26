//
//  Photos.swift
//  SortNAO
//
//  Created by Claude on 2026/02/26.
//

import Foundation
import Photos
import PhotosUI
import SwiftUI
import UIKit

extension SauceNAO {
    @MainActor
    public func add(pickerResults: [PHPickerResult]) async {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SortNAO", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        for result in pickerResults {
            let itemProvider = result.itemProvider

            if let assetIdentifier = result.assetIdentifier {
                self.photoAssetIdentifiers.insert(assetIdentifier)
            }

            guard let image = await loadImage(from: itemProvider) else { continue }

            let fileName = itemProvider.suggestedName ?? UUID().uuidString
            let fileURL = tempDirectory.appendingPathComponent("\(fileName).png")

            guard let data = image.pngData() else { continue }
            do {
                try data.write(to: fileURL)
                self.photosImportedURLs.insert(fileURL)
                if let assetIdentifier = result.assetIdentifier {
                    self.urlToAssetIdentifier[fileURL] = assetIdentifier
                }
                await self.add(file: fileURL)
            } catch {
                debugPrint("Failed to save photo: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    private func loadImage(from itemProvider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                    continuation.resume(returning: image as? UIImage)
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }

    @MainActor
    public func organizeInPhotos() async -> Int {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { return 0 }

        let rootFolder = await Self.findOrCreateFolder(named: "SortNAO")
        guard let rootFolder else { return 0 }

        var organizedCount = 0

        for (category, urls) in self.categorized {
            let albumName = category.albumName()
            guard !albumName.isEmpty else { continue }
            guard let album = await Self.findOrCreateAlbum(named: albumName, in: rootFolder) else { continue }

            let assetIdentifiers = urls.compactMap { url -> String? in
                self.urlToAssetIdentifier[url]
            }

            if !assetIdentifiers.isEmpty {
                let albumId = album.localIdentifier
                let count = await Task.detached {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIdentifiers, options: nil)
                    let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
                    if let fetchedAlbum = collections.firstObject {
                        do {
                            try await PHPhotoLibrary.shared().performChanges {
                                let albumChangeRequest = PHAssetCollectionChangeRequest(for: fetchedAlbum)
                                albumChangeRequest?.addAssets(assets)
                            }
                            return assets.count
                        } catch {
                            debugPrint("Failed to add assets to album: \(error.localizedDescription)")
                        }
                    }
                    return 0
                }.value
                organizedCount += count
            }

            let nonAssetURLs = urls.filter {
                self.urlToAssetIdentifier[$0] == nil && self.photosImportedURLs.contains($0)
            }
            if !nonAssetURLs.isEmpty {
                let albumId = album.localIdentifier
                for url in nonAssetURLs {
                    let success = await Task.detached {
                        let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
                        if let fetchedAlbum = collections.firstObject {
                            do {
                                try await PHPhotoLibrary.shared().performChanges {
                                    let creationRequest = PHAssetCreationRequest.forAsset()
                                    creationRequest.addResource(with: .photo, fileURL: url, options: nil)
                                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: fetchedAlbum)
                                    if let placeholder = creationRequest.placeholderForCreatedAsset {
                                        albumChangeRequest?.addAssets([placeholder] as NSArray)
                                    }
                                }
                                return true
                            } catch {
                                debugPrint("Failed to create asset in album: \(error.localizedDescription)")
                            }
                        }
                        return false
                    }.value
                    if success { organizedCount += 1 }
                }
            }
        }

        return organizedCount
    }

    nonisolated private static func findOrCreateFolder(named name: String) async -> PHCollectionList? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", name)
        let folders = PHCollectionList.fetchTopLevelUserCollections(with: fetchOptions)

        for index in 0..<folders.count {
            if let folder = folders.object(at: index) as? PHCollectionList {
                return folder
            }
        }

        let box = PlaceholderBox()
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: name)
                box.identifier = request.placeholderForCreatedCollectionList.localIdentifier
            }
            if let identifier = box.identifier {
                let result = PHCollectionList.fetchCollectionLists(
                    withLocalIdentifiers: [identifier],
                    options: nil
                )
                return result.firstObject
            }
        } catch {
            debugPrint("Failed to create folder: \(error.localizedDescription)")
        }

        return nil
    }

    nonisolated private static func findOrCreateAlbum(
        named name: String,
        in folder: PHCollectionList
    ) async -> PHAssetCollection? {
        let existingAlbums = PHCollection.fetchCollections(in: folder, options: nil)
        for index in 0..<existingAlbums.count {
            if let album = existingAlbums.object(at: index) as? PHAssetCollection,
               album.localizedTitle == name {
                return album
            }
        }

        let box = PlaceholderBox()
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let albumRequest = PHAssetCollectionChangeRequest
                    .creationRequestForAssetCollection(withTitle: name)
                box.identifier = albumRequest.placeholderForCreatedAssetCollection.localIdentifier
                let folderRequest = PHCollectionListChangeRequest(for: folder)
                if let placeholder = albumRequest.placeholderForCreatedAssetCollection as PHObjectPlaceholder? {
                    folderRequest?.addChildCollections([placeholder] as NSArray)
                }
            }
            if let identifier = box.identifier {
                let result = PHAssetCollection.fetchAssetCollections(
                    withLocalIdentifiers: [identifier],
                    options: nil
                )
                return result.firstObject
            }
        } catch {
            debugPrint("Failed to create album: \(error.localizedDescription)")
        }

        return nil
    }
}

private final class PlaceholderBox: @unchecked Sendable {
    var identifier: String?
}
