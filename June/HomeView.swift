import SwiftUI

struct HomeView: View {
    @Environment(AuthManager.self) private var auth
    @State private var selectedFeed: FeedType = .forYou
    @State private var forYouPosts: [JunePost] = []
    @State private var followingPosts: [JunePost] = []
    @State private var forYouCursor: String? = nil
    @State private var followingCursor: String? = nil
    @State private var isRefreshing = false
    @State private var isLoadingMore = false
    @State private var showCompose = false
    @State private var navPath = NavigationPath()

    enum FeedType: String, CaseIterable {
        case forYou     = "For You"
        case following  = "Following"
    }

    private var activePosts: [JunePost] {
        selectedFeed == .forYou ? forYouPosts : followingPosts
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack(alignment: .bottomTrailing) {
                Color.juneBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Feed picker
                    HStack(spacing: 0) {
                        ForEach(FeedType.allCases, id: \.self) { feed in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFeed = feed
                                }
                            } label: {
                                VStack(spacing: 0) {
                                    Text(feed.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(selectedFeed == feed ? .bold : .regular)
                                        .foregroundStyle(selectedFeed == feed
                                            ? Color.juneTextPrimary
                                            : Color.juneTextSecondary)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)

                                    Rectangle()
                                        .fill(selectedFeed == feed ? Color.juneAccent : Color.clear)
                                        .frame(height: 2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Divider().background(Color.juneBorder)
                    }

                    // Posts list
                    List {
                        ForEach(activePosts) { post in
                            PostCardView(post: post) {
                                removePosts(id: post.id)
                            }
                            .listRowInsets(.init())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.juneBackground)
                        }

                        // Load more
                        if isLoadingMore {
                            HStack { Spacer(); ProgressView().tint(Color.juneAccent); Spacer() }
                                .listRowBackground(Color.juneBackground)
                                .listRowSeparator(.hidden)
                        } else {
                            Color.clear.frame(height: 1)
                                .listRowBackground(Color.juneBackground)
                                .listRowSeparator(.hidden)
                                .onAppear { loadMore() }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.juneBackground)
                    .refreshable {
                        await refreshFeed()
                    }
                    .overlay {
                        if activePosts.isEmpty && !isRefreshing {
                            emptyView
                        }
                    }
                }

                // Compose FAB
                Button {
                    showCompose = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.juneAccent)
                        .clipShape(Circle())
                        .shadow(color: Color.juneAccent.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("June")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navPath.append(NavDestination.profile(auth.user?.username ?? ""))
                    } label: {
                        UserAvatar(url: auth.user?.avatarUrl, initials: auth.user?.initials ?? "?", size: 32)
                    }
                }
            }
            .navigationDestination(for: NavDestination.self) { dest in
                destinationView(for: dest)
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposeView { newPost in
                forYouPosts.insert(newPost, at: 0)
                followingPosts.insert(newPost, at: 0)
            }
        }
        .task {
            if forYouPosts.isEmpty { await loadFeed(feed: .forYou, refresh: true) }
            if followingPosts.isEmpty { await loadFeed(feed: .following, refresh: true) }
        }
    }

    @ViewBuilder
    private func destinationView(for dest: NavDestination) -> some View {
        switch dest {
        case .post(let id):           PostDetailView(postId: id)
        case .profile(let username):  ProfileView(username: username)
        case .messageThread:          EmptyView()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "newspaper")
                .font(.system(size: 44))
                .foregroundStyle(Color.juneTextTertiary)
            Text(selectedFeed == .forYou ? "Nothing here yet" : "Follow people to see their posts")
                .font(.headline)
                .foregroundStyle(Color.juneTextPrimary)
            Text(selectedFeed == .forYou ? "Be the first to post something" : "Explore to find people")
                .font(.subheadline)
                .foregroundStyle(Color.juneTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }

    private func refreshFeed() async {
        isRefreshing = true
        await loadFeed(feed: selectedFeed, refresh: true)
        isRefreshing = false
    }

    private func loadMore() {
        let cursor = selectedFeed == .forYou ? forYouCursor : followingCursor
        guard cursor != nil, !isLoadingMore else { return }
        Task { await loadFeed(feed: selectedFeed, refresh: false) }
    }

    private func loadFeed(feed: FeedType, refresh: Bool) async {
        if !refresh { isLoadingMore = true }
        defer { isLoadingMore = false }

        let cursor = refresh ? nil : (feed == .forYou ? forYouCursor : followingCursor)
        do {
            let response: FeedResponse = feed == .forYou
                ? try await APIService.shared.forYouFeed(cursor: cursor)
                : try await APIService.shared.followingFeed(cursor: cursor)

            if feed == .forYou {
                forYouPosts = refresh ? response.posts : forYouPosts + response.posts
                forYouCursor = response.nextCursor
            } else {
                followingPosts = refresh ? response.posts : followingPosts + response.posts
                followingCursor = response.nextCursor
            }
        } catch { }
    }

    private func removePosts(id: String) {
        forYouPosts.removeAll { $0.id == id }
        followingPosts.removeAll { $0.id == id }
    }
}
