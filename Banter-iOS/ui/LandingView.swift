import SwiftUI

/// The root switch: pick a league, or chat about the one already picked.
struct LandingView: View {
    @Environment(ChatViewModel.self) private var chatViewModel

    var body: some View {
        Group {
            if let league = chatViewModel.selectedLeague {
                ChatView(league: league)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                LeagueSelectionView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: chatViewModel.selectedLeague)
    }
}
