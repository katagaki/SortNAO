//
//  ToroThumbActivityIndicator.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/16.
//

import SwiftUI

struct ToroThumbActivityIndicator: View {
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(.activityIndicatorBackground)
                .frame(width: 72.0, height: 72.0)
            ProgressView()
                .frame(width: 32.0, height: 32.0)
        }
    }
}
