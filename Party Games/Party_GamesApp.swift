//
//  Party_GamesApp.swift
//  Party Games
//
//  Created by Mohamed Abdelmagid on 8/7/25.
//

import SwiftUI
import SwiftData

@main
struct Party_GamesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            GameCategory.self,
            GameCard.self,
            GameSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

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
        #if os(macOS)
        .defaultSize(width: 900, height: 700)
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands()
        }
        #endif
    }
}

// MARK: - macOS App Commands

#if os(macOS)
struct AppCommands: Commands {
    var body: some Commands {
        // File menu commands
        CommandGroup(replacing: .newItem) {
            Button("New Game Session") {
                // Handle new game session
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Shuffle Categories") {
                // Handle shuffle
            }
            .keyboardShortcut("s", modifiers: .command)
        }
        
        // Game menu commands
        CommandMenu("Game") {
            Button("Previous Card") {
                NotificationCenter.default.post(name: .previousCard, object: nil)
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)
            
            Button("Next Card") {
                NotificationCenter.default.post(name: .nextCard, object: nil)
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)
            
            Button("Skip Card") {
                NotificationCenter.default.post(name: .skipCard, object: nil)
            }
            .keyboardShortcut("k", modifiers: .command)
            
            Button("Favorite Card") {
                NotificationCenter.default.post(name: .favoriteCard, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)
            
            Divider()
            
            Button("Restart Session") {
                NotificationCenter.default.post(name: .restartSession, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            
            Button("End Session") {
                NotificationCenter.default.post(name: .endSession, object: nil)
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])
        }
        
        // View menu commands
        CommandGroup(after: .toolbar) {
            Button("Show Game Rules") {
                NotificationCenter.default.post(name: .showGameRules, object: nil)
            }
            .keyboardShortcut("?", modifiers: .command)
            
            Button("Show Session Menu") {
                NotificationCenter.default.post(name: .showSessionMenu, object: nil)
            }
            .keyboardShortcut("m", modifiers: .command)
        }
    }
}

// MARK: - Notification Names for macOS Commands

extension Notification.Name {
    static let previousCard = Notification.Name("previousCard")
    static let nextCard = Notification.Name("nextCard")
    static let skipCard = Notification.Name("skipCard")
    static let favoriteCard = Notification.Name("favoriteCard")
    static let restartSession = Notification.Name("restartSession")
    static let endSession = Notification.Name("endSession")
    static let showGameRules = Notification.Name("showGameRules")
    static let showSessionMenu = Notification.Name("showSessionMenu")
}
#endif
