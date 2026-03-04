
//
//  SnippetsApp.swift
//  Snippets
//

import SwiftUI
import SwiftData

@main
struct SnippetsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipItem.self,
            ClipFolder.self,
            ClipTag.self,
        ])

        // Use App Group container so the Share Extension can access the same store
        let storeURL: URL = {
            if let groupURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.devohn.snippets"
            ) {
                return groupURL.appendingPathComponent("Snippets.store")
            }
            return URL.documentsDirectory.appendingPathComponent("Snippets.store")
        }()

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
