import SwiftUI

struct MainTabView: View {
    @Environment(AuthManager.self) private var auth
    @State private var selectedTab = 0
    @State private var unreadNotifications = 0
    @State private var unreadDMs = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: selectedTab == 0 ? "house.fill" : "house", value: 0) {
                HomeView()
            }
            Tab("Search", systemImage: "magnifyingglass", value: 1) {
                SearchView()
            }
            Tab("Alerts", systemImage: selectedTab == 2 ? "bell.fill" : "bell", value: 2) {
                AlertsView(unreadCount: $unreadNotifications)
            }
            .badge(unreadNotifications > 0 ? "\(unreadNotifications)" : nil)
            Tab("Messages", systemImage: selectedTab == 3 ? "message.fill" : "message", value: 3) {
                DMsView()
            }
        }
        .tint(Color.juneAccent)
        .task {
            await loadBadgeCounts()
        }
    }

    private func loadBadgeCounts() async {
        unreadNotifications = (try? await APIService.shared.getUnreadCount()) ?? 0
    }
}
