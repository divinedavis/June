import SwiftUI

struct ProfileView: View {
    let username: String
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var profile: JuneUser?
    @State private var posts: [JunePost] = []
    @State private var isLoading = true
    @State private var isFollowing = false
    @State private var cursor: String?
    @State private var isLoadingMore = false
    @State private var showSettings = false

    private var isOwnProfile: Bool { auth.user?.username == username }

    var body: some View {
        ZStack {
            Color.juneBackground.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(Color.juneAccent)
            } else if let profile {
                profileContent(profile)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.juneTextTertiary)
                    Text("User not found")
                        .foregroundStyle(Color.juneTextSecondary)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isOwnProfile {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.juneTextPrimary)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .task { await load() }
    }

    @ViewBuilder
    private func profileContent(_ profile: JuneUser) -> some View {
        List {
            // Header
            Section {
                profileHeader(profile)
            }
            .listRowInsets(.init())
            .listRowBackground(Color.juneBackground)
            .listRowSeparator(.hidden)

            // Posts header
            Section {
                HStack {
                    Text("Posts")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.juneTextPrimary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .listRowInsets(.init())
            .listRowBackground(Color.juneBackground)
            .listRowSeparator(.hidden)

            // Posts
            if profile.canView ?? profile.isPublic {
                ForEach(posts) { post in
                    PostCardView(post: post) {
                        posts.removeAll { $0.id == post.id }
                    }
                    .listRowInsets(.init())
                    .listRowBackground(Color.juneBackground)
                    .listRowSeparator(.hidden)
                }

                // Load more
                if cursor != nil {
                    HStack { Spacer(); ProgressView().tint(Color.juneAccent); Spacer() }
                        .listRowBackground(Color.juneBackground)
                        .listRowSeparator(.hidden)
                        .onAppear { loadMore() }
                }

                if posts.isEmpty && !isLoading {
                    Text("No posts yet")
                        .foregroundStyle(Color.juneTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                        .listRowBackground(Color.juneBackground)
                        .listRowSeparator(.hidden)
                }
            } else {
                // Private account
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.juneTextTertiary)
                    Text("This account is private")
                        .font(.headline)
                        .foregroundStyle(Color.juneTextPrimary)
                    Text("Follow to see their posts")
                        .font(.subheadline)
                        .foregroundStyle(Color.juneTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .listRowBackground(Color.juneBackground)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await load() }
    }

    @ViewBuilder
    private func profileHeader(_ profile: JuneUser) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Avatar + Follow
            HStack(alignment: .bottom) {
                UserAvatar(url: profile.avatarUrl, initials: profile.initials, size: 80)
                Spacer()

                if isOwnProfile {
                    NavigationLink(destination: SettingsView()) {
                        Text("Edit profile")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.juneTextPrimary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .overlay(Capsule().stroke(Color.juneBorder))
                    }
                } else {
                    Button { handleFollow() } label: {
                        Text(isFollowing ? "Following" : "Follow")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(isFollowing ? Color.juneTextPrimary : .black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(isFollowing ? Color.clear : Color.juneTextPrimary)
                            .clipShape(Capsule())
                            .overlay(isFollowing ? Capsule().stroke(Color.juneBorder) : nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Name + username
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.juneTextPrimary)

                HStack(spacing: 6) {
                    Text("@\(profile.username)")
                        .foregroundStyle(Color.juneTextSecondary)
                    if !profile.isPublic {
                        HStack(spacing: 3) {
                            Image(systemName: "lock.fill").font(.caption2)
                            Text("Private")
                        }
                        .font(.caption)
                        .foregroundStyle(Color.juneTextTertiary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.juneSurface)
                        .clipShape(RoundedRectangle(cornerRadius: JuneRadius.tag))
                    }
                }
                .font(.subheadline)

                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(Color.juneTextPrimary)
                        .padding(.top, 6)
                }

                if let created = profile.createdAt {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Joined \(created.joinedDate)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.juneTextTertiary)
                    .padding(.top, 4)
                }

                // Stats
                HStack(spacing: 20) {
                    StatView(count: profile.followingCount, label: "Following")
                    StatView(count: profile.followerCount, label: "Followers")
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            Divider().background(Color.juneBorder)
        }
    }

    private func handleFollow() {
        let was = isFollowing
        isFollowing = !was
        if var p = profile {
            p.followerCount += was ? -1 : 1
            profile = p
        }
        Task {
            do {
                if was { try await APIService.shared.unfollow(username: username) }
                else    { try await APIService.shared.follow(username: username)  }
            } catch {
                isFollowing = was
            }
        }
    }

    private func load() async {
        isLoading = true
        async let profileTask = APIService.shared.getUser(username: username)
        async let postsTask   = APIService.shared.getUserPosts(username: username)
        profile = try? await profileTask
        isFollowing = profile?.isFollowing ?? false
        if let r = try? await postsTask {
            posts = r.posts
            cursor = r.nextCursor
        }
        isLoading = false
    }

    private func loadMore() {
        guard let cursor, !isLoadingMore else { return }
        isLoadingMore = true
        Task {
            if let r = try? await APIService.shared.getUserPosts(username: username, cursor: cursor) {
                posts.append(contentsOf: r.posts)
                self.cursor = r.nextCursor
            }
            isLoadingMore = false
        }
    }
}

extension String {
    var joinedDate: String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = fmt.date(from: self) ?? Date()
        let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let m = Calendar.current.component(.month, from: date) - 1
        let y = Calendar.current.component(.year, from: date)
        return "\(months[m]) \(y)"
    }
}
