//
//  Filenames.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/20.
//

import Foundation

extension SauceNAO {
    public func renameAll(
        includeMaterialName: Bool = true,
        includeCharacterNames: Bool = true,
        rehearse: Bool = false
    ) -> AsyncStream<(URL, URL)> {
        AsyncStream { continuation in
            var urls: [URL] = []
            if rehearse {
                urls.append(
                    contentsOf: [
                        self.succeeded.keys.randomElement(),
                        self.succeeded.keys.randomElement(),
                        self.succeeded.keys.randomElement()
                    ].compactMap({ $0 })
                )
            } else {
                urls.append(contentsOf: self.succeeded.keys)
            }
            for url in urls {
                guard let result = self.succeeded[url] else { continue }
                var newFileName = url.lastPathComponent
                if includeCharacterNames,
                   let characters = result.data.characters {
                    newFileName = "\(characters) - \(newFileName)"
                }
                if includeMaterialName,
                   let material = result.data.material {
                    newFileName = "\(material) - \(newFileName)"
                }
                let newURL = url
                    .deletingLastPathComponent()
                    .appendingPathComponent(newFileName)
                if !rehearse {
                    do {
                        try fileManager.moveItem(at: url, to: newURL)
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                }
                continuation.yield((url, newURL))
            }
            continuation.finish()
        }
    }
}
