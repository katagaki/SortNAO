//
//  SortNAOIntentError.swift
//  SortNAO
//

import Foundation

enum SortNAOIntentError: LocalizedError {
    case noResults

    var errorDescription: String? {
        switch self {
        case .noResults:
            return NSLocalizedString("Intent.Error.NoResults", comment: "")
        }
    }
}
