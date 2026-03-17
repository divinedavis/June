import SwiftUI

struct PostCardView: View {
    @Environment(AuthManager.self) private var auth
    @State var post: JunePost
    var onDelete: (() -> Void)? = nil
    var showBorder: Bool = true
    @State private var showDeleteAlert = false
    @State private var isAnimatingLike = false

    var isOwn: Bool { auth.user?.id == post.user.id }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            NavigationLink(value: NavDestination.profile(post.user.username)) {
                UserAvatar(url: post.user.avatarUrl, initials: post.user.initials)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                // Header row
                HStack(alignment: .center) {
                    NavigationLink(value: NavDestination.profile(post.user.username)) {
                        HStack(spacing: 4) {
                            Text(post.user.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.juneTextPrimary)
                                .lineLimit(1)
                            Text("@\(post.user.username)")
                                .font(.subheadline)
                                .foregroundStyle(Color.juneTextSecondary)
                                .lineLimit(1)
                            Text("·")
                                .foregroundStyle(Color.juneTextSecondary)
                            Text(post.timeAgo)
                                .font(.subheadline)
                                .foregroundStyle(Color.juneTextSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if isOwn {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(Color.juneTextTertiary)
                                .font(.footnote)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Content
                NavigationLink(value: NavDestination.post(post.id)) {
                    Text(post.content)
                        .font(.body)
                        .foregroundStyle(Color.juneTextPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                // Media
                if let mediaUrl = post.mediaUrl, let url = URL(string: mediaUrl) {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: JuneRadius.card))
                        }
                    }
                }

                // Actions
                HStack(spacing: 28) {
                    // Reply
                    NavigationLink(value: NavDestination.post(post.id)) {
                        ActionButton(icon: "bubble.left", count: post.replyCount, color: .juneTextTertiary)
                    }
                    .buttonStyle(.plain)

                    // Repost
                    Button { handleRepost() } label: {
                        ActionButton(icon: "repeat", count: post.repostCount,
                                     color: post.isReposted ? .juneRepost : .juneTextTertiary)
                    }
                    .buttonStyle(.plain)

                    // Like
                    Button { handleLike() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                .font(.subheadline)
                                .foregroundStyle(post.isLiked ? Color.juneLike : Color.juneTextTertiary)
                                .scaleEffect(isAnimatingLike ? 1.25 : 1)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isAnimatingLike)
                            if post.likeCount > 0 {
                                Text(post.likeCount.formatted)
                                    .font(.caption)
                                    .foregroundStyle(post.isLiked ? Color.juneLike : Color.juneTextTertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // Views
                    ActionButton(icon: "eye", count: post.viewCount, color: .juneTextTertiary)
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.juneBackground)
        .overlay(alignment: .bottom) {
            if showBorder {
                Divider()
                    .background(Color.juneBorder)
            }
        }
        .alert("Delete post?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await APIService.shared.deletePost(id: post.id)
                    onDelete?()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func handleLike() {
        let wasLiked = post.isLiked
        post.isLiked = !wasLiked
        post.likeCount += wasLiked ? -1 : 1
        isAnimatingLike = !wasLiked
        Task {
            do {
                if wasLiked {
                    try await APIService.shared.unlikePost(id: post.id)
                } else {
                    try await APIService.shared.likePost(id: post.id)
                }
            } catch {
                post.isLiked = wasLiked
                post.likeCount += wasLiked ? 1 : -1
            }
            if !wasLiked {
                try? await Task.sleep(for: .milliseconds(300))
                isAnimatingLike = false
            }
        }
    }

    private func handleRepost() {
        let wasReposted = post.isReposted
        post.isReposted = !wasReposted
        post.repostCount += wasReposted ? -1 : 1
        Task {
            do {
                if wasReposted {
                    try await APIService.shared.unrepost(id: post.id)
                } else {
                    try await APIService.shared.repost(id: post.id)
                }
            } catch {
                post.isReposted = wasReposted
                post.repostCount += wasReposted ? 1 : -1
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
            if count > 0 {
                Text(count.formatted)
                    .font(.caption)
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Navigation destinations

enum NavDestination: Hashable {
    case post(String)
    case profile(String)
    case messageThread(Conversation)

    static func == (lhs: NavDestination, rhs: NavDestination) -> Bool {
        switch (lhs, rhs) {
        case (.post(let a), .post(let b)):       return a == b
        case (.profile(let a), .profile(let b)): return a == b
        case (.messageThread(let a), .messageThread(let b)): return a.id == b.id
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .post(let id):           hasher.combine("post"); hasher.combine(id)
        case .profile(let username):  hasher.combine("profile"); hasher.combine(username)
        case .messageThread(let c):   hasher.combine("thread"); hasher.combine(c.id)
        }
    }
}
