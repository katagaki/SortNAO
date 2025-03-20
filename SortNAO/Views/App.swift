//
//  SortNAOApp.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI

@main
struct SortNAOApp: App {
    @State var nao: SauceNAO = SauceNAO()

    var body: some Scene {
        WindowGroup {
            OrganizerView()
                .environment(nao)
        }
    }
}
