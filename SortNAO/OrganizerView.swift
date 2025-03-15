//
//  OrganizerView.swift
//  SortNAO
//
//  Created by シン・ジャスティン on 2025/03/15.
//

import Komponents
import SwiftUI

struct OrganizerView: View {
    @State var viewPath: [ViewPath] = []
    
    var body: some View {
        NavigationStack(path: $viewPath) {
            ToroList {
                Text("""
                     Welcome to SortNAO!
                     To get started, tap \(Image(systemName: "plus")) and select a folder to add your files.
                     """)
                ToroSection(header: "hello", footer: "uma musume") {
                    Text("world")
                }
                ToroSection(header: "Uncategorized", footer: "Categorize these files", contentInsets: .init()) {
                    ImageGrid()
                }
                ToroSection(header: "ブルーアーカイブ", contentInsets: .init()) {
                    ImageGrid()
                }
                ToroSection(header: "ウマ娘", contentInsets: .init()) {
                    ImageGrid()
                }
            }
            .background(
                .linearGradient(
                    colors: [.backgroundGradientTop, .backgroundGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .bottomAccessoryBar(
                addAction: doNothing,
                organizeAction: doNothing
            )
            .navigationTitle("SortNAO")
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                case .settings: SettingsView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ToroToolbarButton(iconName: "gearshape.fill", action: openSettingsView)
                }
            }
        }
    }
    
    func openSettingsView() {
        viewPath.append(.settings)
    }

    func doNothing() {
        
    }
}
