import SwiftData
import SwiftUI

@main struct BanterApp: App {
    private let container: ModelContainer
    private let chatViewModel: ChatViewModel

    init() {
        // Start watching the network now, so the first sports question sees a real answer.
        _ = NetworkMonitor.shared

        do {
            container = try ModelContainer(for: CachedStanding.self, CachedGame.self)
        } catch {
            fatalError("Could not open the local database: \(error)")
        }
        chatViewModel = ChatViewModel(store: LeagueStore(context: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            LandingView()
        }
        .environment(chatViewModel)
        .modelContainer(container)
    }
}
