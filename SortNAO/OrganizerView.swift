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
    @State var apiKey: String = ""
    
    var body: some View {
        NavigationStack(path: $viewPath) {
            ToroList {
                ToroSection(header: "Welcome to SortNAO") {
                    Text("""
                         To get started, tap \(Image(systemName: "plus")) and select a folder to add your files.
                         """)
                }
                ToroSection(header: "Set Up API Key") {
                    Text("Enter your SauceNAO API key below.")
                    SecureField("SauceNAO API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    ActionButton(text: "Save", icon: "key.fill", isPrimary: true, action: doNothing)
                }
                ToroSection(header: "Uncategorized", footer: "Categorize these files", contentInsets: .init()) {
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
                    HStack {
                        ToroToolbarButton(iconName: "person.fill", action: openAccountView)
                        ToroToolbarButton(iconName: "gearshape.fill", action: openSettingsView)
                    }
                }
            }
        }
    }
    
    func openSettingsView() {
        viewPath.append(.settings)
    }

    func openAccountView() {
        
    }

    func doNothing() {
        
    }
}
