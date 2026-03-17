import SwiftUI

struct ComposeView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    var replyToPost: JunePost? = nil
    var onPosted: ((JunePost) -> Void)? = nil

    @State private var text = ""
    @State private var isPosting = false
    @FocusState private var isFocused: Bool

    private let limit = 240
    private var remaining: Int { limit - text.count }
    private var canPost: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty && remaining >= 0 && !isPosting }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.juneBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let reply = replyToPost {
                        HStack(alignment: .top, spacing: 12) {
                            UserAvatar(url: reply.user.avatarUrl, initials: reply.user.initials)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reply.user.displayName)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.juneTextPrimary)
                                Text(reply.content)
                                    .foregroundStyle(Color.juneTextSecondary)
                                    .lineLimit(2)
                            }
                        }
                        .font(.subheadline)
                        .padding()
                        .background(Color.juneSurface)

                        Text("Replying to @\(reply.user.username)")
                            .font(.caption)
                            .foregroundStyle(Color.juneAccent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        UserAvatar(url: auth.user?.avatarUrl, initials: auth.user?.initials ?? "?")

                        TextEditor(text: $text)
                            .focused($isFocused)
                            .font(.body)
                            .foregroundStyle(Color.juneTextPrimary)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 120)
                            .overlay(alignment: .topLeading) {
                                if text.isEmpty {
                                    Text(replyToPost != nil ? "Post your reply" : "What's on your mind?")
                                        .foregroundStyle(Color.juneTextTertiary)
                                        .font(.body)
                                        .allowsHitTesting(false)
                                }
                            }
                    }
                    .padding()

                    Spacer()

                    // Footer
                    VStack(spacing: 0) {
                        Divider().background(Color.juneBorder)
                        HStack {
                            Spacer()
                            // Character count ring
                            ZStack {
                                Circle()
                                    .stroke(Color.juneBorder, lineWidth: 2)
                                Circle()
                                    .trim(from: 0, to: max(0, CGFloat(text.count) / CGFloat(limit)))
                                    .stroke(remaining < 0 ? Color.juneError : remaining < 20 ? Color.juneAccent : Color.juneAccent,
                                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.1), value: text.count)
                                if remaining <= 20 {
                                    Text("\(remaining)")
                                        .font(.caption2)
                                        .foregroundStyle(remaining < 0 ? Color.juneError : Color.juneTextSecondary)
                                }
                            }
                            .frame(width: 28, height: 28)
                            .padding(.trailing, 12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
            }
            .navigationTitle(replyToPost != nil ? "Reply" : "New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.juneTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        post()
                    } label: {
                        Group {
                            if isPosting {
                                ProgressView().tint(.black)
                            } else {
                                Text("Post")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(canPost ? Color.juneAccent : Color.juneAccent.opacity(0.4))
                        .clipShape(Capsule())
                    }
                    .disabled(!canPost)
                }
            }
        }
        .onAppear { isFocused = true }
    }

    private func post() {
        guard canPost else { return }
        isPosting = true
        Task {
            do {
                let wrapper = try await APIService.shared.createPost(
                    content: text.trimmingCharacters(in: .whitespaces),
                    replyToId: replyToPost?.id
                )
                onPosted?(wrapper.post)
                dismiss()
            } catch { }
            isPosting = false
        }
    }
}
