import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var filterType: FilterType = .all
    @State private var users: [JuneUser] = []
    @State private var posts: [JunePost] = []
    @State private var trending: [JunePost] = []
    @State private var isSearching = false
    @State private var navPath = NavigationPath()

    enum FilterType: String, CaseIterable {
        case all = "All"; case people = "People"; case posts = "Posts"
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                Color.juneBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.juneTextTertiary)
                        TextField("Search June", text: $query)
                            .foregroundStyle(Color.juneTextPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.search)
                            .onSubmit { search() }
                        if !query.isEmpty {
                            Button {
                                query = ""
                                users = []
                                posts = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.juneTextTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.juneSurface)
                    .clipShape(RoundedRectangle(cornerRadius: JuneRadius.input))
                    .overlay(RoundedRectangle(cornerRadius: JuneRadius.input).stroke(Color.juneBorder))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Filter chips (only when searching)
                    if !query.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(FilterType.allCases, id: \.self) { type in
                                    Button {
                                        filterType = type
                                    } label: {
                                        Text(type.rawValue)
                                            .font(.subheadline)
                                            .foregroundStyle(filterType == type ? .black : Color.juneTextSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 7)
                                            .background(filterType == type ? Color.juneAccent : Color.juneSurface)
                                            .clipShape(Capsule())
                                            .overlay(filterType == type ? nil : Capsule().stroke(Color.juneBorder))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 8)
                    }

                    Divider().background(Color.juneBorder)

                    // Results / Trending
                    if isSearching {
                        Spacer()
                        ProgressView().tint(Color.juneAccent)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if query.isEmpty {
                                    sectionHeader("Trending")
                                    ForEach(trending) { post in
                                        PostCardView(post: post)
                                    }
                                } else {
                                    if (filterType == .all || filterType == .people) && !users.isEmpty {
                                        sectionHeader("People")
                                        ForEach(users) { user in
                                            UserRow(user: user)
                                                .onTapGesture {
                                                    navPath.append(NavDestination.profile(user.username))
                                                }
                                        }
                                    }

                                    if (filterType == .all || filterType == .posts) && !posts.isEmpty {
                                        sectionHeader("Posts")
                                        ForEach(posts) { post in
                                            PostCardView(post: post)
                                        }
                                    }

                                    if users.isEmpty && posts.isEmpty {
                                        VStack(spacing: 12) {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 40))
                                                .foregroundStyle(Color.juneTextTertiary)
                                            Text("No results for "\(query)"")
                                                .font(.headline)
                                                .foregroundStyle(Color.juneTextSecondary)
                                        }
                                        .padding(.top, 60)
                                    }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: NavDestination.self) { dest in
                switch dest {
                case .profile(let u): ProfileView(username: u)
                case .post(let id): PostDetailView(postId: id)
                default: EmptyView()
                }
            }
        }
        .onChange(of: query) { _, new in
            if new.isEmpty { users = []; posts = [] }
            else { debounceSearch() }
        }
        .task { trending = (try? await APIService.shared.trending()) ?? [] }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(Color.juneTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    @State private var searchTask: Task<Void, Never>?

    private func debounceSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled { search() }
        }
    }

    private func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        Task {
            if let response = try? await APIService.shared.search(query: query) {
                users = response.users ?? []
                posts = response.posts ?? []
            }
            isSearching = false
        }
    }
}

struct UserRow: View {
    let user: JuneUser

    var body: some View {
        HStack(spacing: 12) {
            UserAvatar(url: user.avatarUrl, initials: user.initials)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(user.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.juneTextPrimary)
                    if !user.isPublic {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.juneTextTertiary)
                    }
                }
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(Color.juneTextSecondary)
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(Color.juneTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider().background(Color.juneBorder)
        }
    }
}
