//
//  ftcrApp.swift
//  ftcr Watch App
//
//  Created by Jian Qin on 2024/8/28.
//

import SwiftUI
import SwiftData

@main
struct ftcr_Watch_AppApp: App {
    
    var sharedModelContainer: ModelContainer = {
            let scheme = Schema([
                // entities here
                ImageModel.self
            ])
            
            let modelConfiguration = ModelConfiguration(schema: scheme,
                                                        isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: scheme, configurations: modelConfiguration)
            } catch {
                fatalError("Could not create model container \(error)")
            }
        
        }()
        
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
