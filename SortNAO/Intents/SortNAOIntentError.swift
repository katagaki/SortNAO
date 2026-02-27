//
//  SortNAOIntentError.swift
//  SortNAO
//

import Foundation

enum SortNAOIntentError: LocalizedError, CustomNSError {
    case noResults

    static var errorDomain: String { "com.tsubuzaki.SortNAO.IntentError" }

    var errorCode: Int {
        switch self {
        case .noResults: return 1
        }
    }

    var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: errorDescription ?? ""]
    }

    var errorDescription: String? {
        switch self {
        case .noResults:
            return NSLocalizedString("Intent.Error.NoResults", comment: "")
        }
    }
}
