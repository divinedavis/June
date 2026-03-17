import SwiftUI

struct DMsView: View {
    @Environment(AuthManager.self) private var auth
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    @State private var showNewDM = false
    @State private var newDMUsername = ""
    @State private var selectedConversation: Conversation?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.juneBackground.ignoresSafeArea()

                List {
                    ForEach(conversations) { convo in
                        ConversationRow(conversation: convo, currentUserId: auth.user?.id ?? "")
                            .listRowInsets(.init())
                            .listRowBackground(Color.juneBackground)
                            .listRowSeparator(.hidden)
                            .onTapGesture {
                                selectedConversation = convo
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await load() }
                .overlay {
                    if conversations.isEmpty && !isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "message.and.waveform")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.juneTextTertiary)
                            Text("No messages yet")
                                .font(.headline)
                                .foregroundStyle(Color.juneTextPrimary)
                            Text("Start a conversation by tapping the compose button")
                                .font(.subheadline)
                                .foregroundStyle(Color.juneTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                }

                // Compose FAB
                Button {
                    showNewDM = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.juneAccent)
                        .clipShape(Circle())
                        .shadow(color: Color.juneAccent.opacity(0.4), radius: 10, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedConversation) { convo in
                MessageThreadView(conversation: convo, currentUser: auth.user!)
            }
        }
        .sheet(isPresented: $showNewDM) {
            NewDMView { convo in
                conversations.insert(convo, at: 0)
                selectedConversation = convo
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        conversations = (try? await APIService.shared.getConversations()) ?? []
        isLoading = false
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String

    var body: some View {
        HStack(spacing: 12) {
            UserAvatar(
                url: conversation.otherUser.avatarUrl,
                initials: conversation.otherUser.initials,
                size: 52
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.displayName ?? conversation.otherUser.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.juneTextPrimary)
                    Spacer()
                    if let time = conversation.lastMessageTime {
                        Text(time.timeAgo)
                            .font(.caption)
                            .foregroundStyle(Color.juneTextTertiary)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.juneRepost)
                    Text(conversation.lastMessageEncrypted != nil ? "Encrypted message" : "No messages yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.juneTextSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider().background(Color.juneBorder)
        }
    }
}

// MARK: - New DM Sheet

struct NewDMView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var isLoading = false
    @State private var error: String?
    var onStart: (Conversation) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.juneBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.juneTextTertiary)
                        TextField("Search by username", text: $username)
                            .foregroundStyle(Color.juneTextPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.send)
                            .onSubmit { startDM() }
                    }
                    .padding(12)
                    .background(Color.juneSurface)
                    .clipShape(RoundedRectangle(cornerRadius: JuneRadius.input))
                    .overlay(RoundedRectangle(cornerRadius: JuneRadius.input).stroke(Color.juneBorder))
                    .padding()

                    if let error {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.juneError)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.juneTextSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Next") { startDM() }
                        .foregroundStyle(username.isEmpty ? Color.juneTextTertiary : Color.juneAccent)
                        .fontWeight(.semibold)
                        .disabled(username.isEmpty || isLoading)
                }
            }
        }
    }

    private func startDM() {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        error = nil
        Task {
            do {
                let wrapper = try await APIService.shared.startConversation(username: username.lowercased())
                let convo = Conversation(
                    id: wrapper.conversation.id,
                    createdAt: nil,
                    otherUser: wrapper.conversation.otherUser
                )
                onStart(convo)
                dismiss()
            } catch let err {
                error = err.localizedDescription
            }
            isLoading = false
        }
    }
}
