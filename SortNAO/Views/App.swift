//
//  App.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import SwiftUI
import UIKit

@main
struct SortNAOApp: App {
    @State var nao: SauceNAO = SauceNAO()

    var body: some Scene {
        WindowGroup {
            OrganizerView()
                .environment(nao)
                .onOpenURL { url in
                    guard url.scheme == "nao",
                          url.host == "openSauce",
                          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let sauceURLString = components.queryItems?.first(where: { $0.name == "url" })?.value,
                          let sauceURL = URL(string: sauceURLString) else { return }
                    UIApplication.shared.open(sauceURL)
                }
        }
    }
}
