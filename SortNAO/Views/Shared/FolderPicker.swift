//
//  FolderPicker.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI
import UniformTypeIdentifiers

struct FolderPicker: UIViewControllerRepresentable {
    let onFolderPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Using .directory here causes Open button to disappear mysteriously on Mac
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Not implemented
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let picker: FolderPicker

        init(_ picker: FolderPicker) {
            self.picker = picker
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if urls.count == 1 {
                self.picker.onFolderPicked(urls[0])
            }
        }
    }
}
