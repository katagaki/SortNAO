//
//  SortNAOShortcuts.swift
//  SortNAO
//
//  Created by Claude on 2026/02/26.
//

import AppIntents

@available(iOS 18.0, *)
struct SortNAOShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchSauceIntent(),
            phrases: [
                "Search sauce in \(.applicationName)",
                "Find image source with \(.applicationName)",
                "Look up image in \(.applicationName)"
            ],
            shortTitle: "Intent.SearchSauce.Title",
            systemImageName: "sparkle.magnifyingglass"
        )
    }
}
