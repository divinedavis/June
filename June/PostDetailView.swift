import SwiftUI

struct PostDetailView: View {
    let postId: String

    @State private var post: JunePost?
    @State private var replies: [JunePost] = []
    @State private var isLoading = true
    @State private var showReply = false
    @State private var replyText = ""
    @State private var isPosting = false

    var body: some View {
        ZStack {
            Color.juneBackground.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(Color.juneAccent)
            } else if let post {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Original post (expanded)
                            PostCardView(post: post, showBorder: true)

                            // Reply count
                            if !replies.isEmpty {
                                HStack {
                                    Text("\(replies.count) repl\(replies.count == 1 ? "y" : "ies")")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.juneTextSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                Divider().background(Color.juneBorder)
                            }

                            // Replies
                            ForEach(replies) { reply in
                                PostCardView(post: reply)
                            }
                        }
                    }

                    // Reply bar
                    replyBar
                }
            } else {
                Text("Post not found")
                    .foregroundStyle(Color.juneTextSecondary)
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .sheet(isPresented: $showReply) {
            if let post {
                ComposeView(replyToPost: post) { newReply in
                    replies.insert(newReply, at: 0)
                    self.post?.replyCount += 1
                }
            }
        }
    }

    private var replyBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.juneBorder)
            Button {
                showReply = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left")
                        .foregroundStyle(Color.juneTextSecondary)
                    Text("Reply...")
                        .foregroundStyle(Color.juneTextTertiary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.juneBackground)
            }
            .buttonStyle(.plain)
        }
    }

    private func load() async {
        isLoading = true
        async let postTask = APIService.shared.getPost(id: postId)
        async let repliesTask = APIService.shared.getReplies(postId: postId)
        post = try? await postTask
        if let r = try? await repliesTask { replies = r.posts }
        isLoading = false
    }
}
