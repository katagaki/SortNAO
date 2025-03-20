//
//  ViewPath.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Foundation

enum ViewPath: Hashable {
    case account
    case preview(imageURL: URL)
    case more
    case moreAttributions
}
