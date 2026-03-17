import SwiftUI

struct AlertsView: View {
    @Binding var unreadCount: Int
    @State private var notifications: [JuneNotification] = []
    @State private var isLoading = false
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                Color.juneBackground.ignoresSafeArea()

                if isLoading && notifications.isEmpty {
                    ProgressView().tint(Color.juneAccent)
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationRow(notification: notification)
                                .listRowInsets(.init())
                                .listRowBackground(
                                    notification.read ? Color.juneBackground : Color.juneAccentDim
                                )
                                .listRowSeparator(.hidden)
                                .onTapGesture { handle(notification) }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .overlay {
                        if notifications.isEmpty && !isLoading {
                            VStack(spacing: 12) {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 44))
                                    .foregroundStyle(Color.juneTextTertiary)
                                Text("No notifications yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.juneTextPrimary)
                                Text("When someone likes, reposts, or follows you,\nyou'll see it here.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.juneTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavDestination.self) { dest in
                switch dest {
                case .profile(let u): ProfileView(username: u)
                case .post(let id):   PostDetailView(postId: id)
                default: EmptyView()
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        if let response = try? await APIService.shared.getNotifications() {
            notifications = response.notifications
            unreadCount = 0
            try? await APIService.shared.markAllRead()
        }
        isLoading = false
    }

    private func handle(_ notification: JuneNotification) {
        if notification.type == "follow" {
            if let username = notification.fromUser.username {
                navPath.append(NavDestination.profile(username))
            }
        } else if let postId = notification.postId {
            navPath.append(NavDestination.post(postId))
        }
    }
}

struct NotificationRow: View {
    let notification: JuneNotification

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Type icon
            ZStack {
                Circle()
                    .fill(Color(hex: notification.iconColor).opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: notification.iconName)
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: notification.iconColor))
            }

            // Avatar + text
            HStack(alignment: .center, spacing: 10) {
                UserAvatar(
                    url: notification.fromUser.avatarUrl,
                    initials: String((notification.fromUser.displayName ?? notification.fromUser.username ?? "?").prefix(1)).uppercased(),
                    size: 40
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(notification.fromUser.displayName ?? notification.fromUser.username ?? "Someone")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.juneTextPrimary)
                        Text(notification.actionText)
                            .foregroundStyle(Color.juneTextSecondary)
                    }
                    .font(.subheadline)
                    .lineLimit(2)

                    Text(notification.timeAgo)
                        .font(.caption)
                        .foregroundStyle(Color.juneTextTertiary)
                }

                Spacer()

                if !notification.read {
                    Circle()
                        .fill(Color.juneAccent)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Divider().background(Color.juneBorder)
        }
    }
}
