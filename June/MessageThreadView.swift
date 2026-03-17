import SwiftUI

struct MessageThreadView: View {
    var conversation: Conversation
    var currentUser: JuneUser

    @State private var messages: [DMMessage] = []
    @State private var messageText = ""
    @State private var isSending = false
    @State private var isLoading = true
    @FocusState private var inputFocused: Bool

    private var myPrivateKey: String? { KeychainHelper.read(for: KeychainHelper.privateKeyKey) }

    var body: some View {
        ZStack {
            Color.juneBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // E2E badge
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text("End-to-end encrypted")
                        .font(.caption)
                }
                .foregroundStyle(Color.juneRepost)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.juneRepost.opacity(0.08))

                Divider().background(Color.juneBorder)

                // Messages
                if isLoading {
                    Spacer()
                    ProgressView().tint(Color.juneAccent)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(messages) { message in
                                    MessageBubble(
                                        message: message,
                                        isFromMe: message.sender.id == currentUser.id
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: messages.count) {
                            if let last = messages.last {
                                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                            }
                        }
                        .onAppear {
                            if let last = messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Input bar
                Divider().background(Color.juneBorder)
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .focused($inputFocused)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.juneSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.juneBorder))
                        .foregroundStyle(Color.juneTextPrimary)
                        .lineLimit(1...5)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.black)
                            .frame(width: 36, height: 36)
                            .background(messageText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.juneAccent.opacity(0.4) : Color.juneAccent)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.juneBackground)
            }
        }
        .navigationTitle(conversation.otherUser.displayName ?? conversation.otherUser.username)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadMessages() }
    }

    private func loadMessages() async {
        isLoading = true
        guard let response = try? await APIService.shared.getMessages(conversationId: conversation.id) else {
            isLoading = false
            return
        }

        let privateKey = myPrivateKey
        let senderPubKey = conversation.otherUser.publicKey

        messages = response.messages.map { msg in
            var m = msg
            if let privKey = privateKey, let senderPub = senderPubKey {
                let isFromMe = msg.sender.id == currentUser.id
                if isFromMe {
                    if let myPublicKey = KeychainHelper.read(for: KeychainHelper.publicKeyKey) {
                        m.decryptedContent = EncryptionService.decrypt(
                            ciphertextBase64: msg.encryptedContent,
                            nonceBase64: msg.nonce,
                            senderPublicKeyBase64: myPublicKey,
                            recipientPrivateKeyBase64: privKey
                        )
                    }
                } else {
                    m.decryptedContent = EncryptionService.decrypt(
                        ciphertextBase64: msg.encryptedContent,
                        nonceBase64: msg.nonce,
                        senderPublicKeyBase64: senderPub,
                        recipientPrivateKeyBase64: privKey
                    )
                }
            }
            if m.decryptedContent == nil { m.decryptedContent = "🔒 Encrypted" }
            return m
        }
        isLoading = false
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messageText = ""
        isSending = true

        Task {
            do {
                var encrypted = text
                var nonce = "plaintext"

                if let privKey = myPrivateKey,
                   let recipientPubKey = conversation.otherUser.publicKey,
                   let result = try? EncryptionService.encrypt(
                       message: text,
                       recipientPublicKeyBase64: recipientPubKey,
                       senderPrivateKeyBase64: privKey
                   ) {
                    encrypted = result.ciphertext
                    nonce = result.nonce
                }

                var sent = try await APIService.shared.sendMessage(
                    conversationId: conversation.id,
                    encryptedContent: encrypted,
                    nonce: nonce
                )
                sent.decryptedContent = text
                messages.append(sent)
            } catch { }
            isSending = false
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: DMMessage
    let isFromMe: Bool

    var body: some View {
        HStack {
            if isFromMe { Spacer() }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
                Text(message.decryptedContent ?? "🔒")
                    .font(.body)
                    .foregroundStyle(isFromMe ? Color.black : Color.juneTextPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.juneAccent : Color.juneSurfaceElevated)
                    .clipShape(
                        .rect(
                            topLeadingRadius: isFromMe ? 18 : 4,
                            bottomLeadingRadius: 18,
                            bottomTrailingRadius: isFromMe ? 4 : 18,
                            topTrailingRadius: 18
                        )
                    )

                Text(message.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(Color.juneTextTertiary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.72, alignment: isFromMe ? .trailing : .leading)

            if !isFromMe { Spacer() }
        }
    }
}
