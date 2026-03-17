import Foundation

// MARK: - API Service

final class APIService {
    static let shared = APIService()
    private init() {}

    let baseURL = "http://167.71.170.219:4000"

    private var token: String? { KeychainHelper.read(for: KeychainHelper.tokenKey) }

    // MARK: - Core request

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let errBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError.serverError(errBody.error)
            }
            throw APIError.serverError("HTTP \(http.statusCode)")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Auth

    func signup(username: String, email: String, password: String, displayName: String) async throws -> AuthResponse {
        struct Body: Encodable {
            let username, email, password: String
            let display_name: String
        }
        return try await request("/auth/signup", method: "POST",
                                 body: Body(username: username, email: email, password: password, display_name: displayName))
    }

    func login(login: String, password: String) async throws -> AuthResponse {
        struct Body: Encodable { let login, password: String }
        return try await request("/auth/login", method: "POST", body: Body(login: login, password: password))
    }

    func me() async throws -> JuneUser {
        struct Wrapper: Decodable { let user: JuneUser }
        let w: Wrapper = try await request("/auth/me")
        return w.user
    }

    func uploadPublicKey(_ key: String) async throws {
        struct Body: Encodable { let public_key: String }
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/auth/public-key", method: "PUT", body: Body(public_key: key))
    }

    // MARK: - Feed

    func forYouFeed(cursor: String? = nil) async throws -> FeedResponse {
        let q = cursor.map { "?cursor=\($0)" } ?? ""
        return try await request("/feed/for-you\(q)")
    }

    func followingFeed(cursor: String? = nil) async throws -> FeedResponse {
        let q = cursor.map { "?cursor=\($0)" } ?? ""
        return try await request("/feed/following\(q)")
    }

    // MARK: - Posts

    func createPost(content: String, replyToId: String? = nil) async throws -> PostWrapper {
        struct Body: Encodable { let content: String; let reply_to_id: String? }
        return try await request("/posts", method: "POST",
                                 body: Body(content: content, reply_to_id: replyToId))
    }

    func getPost(id: String) async throws -> JunePost {
        let w: PostWrapper = try await request("/posts/\(id)")
        return w.post
    }

    func deletePost(id: String) async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/posts/\(id)", method: "DELETE")
    }

    func likePost(id: String) async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/posts/\(id)/like", method: "POST")
    }

    func unlikePost(id: String) async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/posts/\(id)/like", method: "DELETE")
    }

    func repost(id: String) async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/posts/\(id)/repost", method: "POST")
    }

    func unrepost(id: String) async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/posts/\(id)/repost", method: "DELETE")
    }

    func getReplies(postId: String, cursor: String? = nil) async throws -> FeedResponse {
        let q = cursor.map { "?cursor=\($0)" } ?? ""
        return try await request("/posts/\(postId)/replies\(q)")
    }

    // MARK: - Users

    func getUser(username: String) async throws -> JuneUser {
        struct Wrapper: Decodable { let user: JuneUser }
        let w: Wrapper = try await request("/users/\(username)")
        return w.user
    }

    func getUserPosts(username: String, cursor: String? = nil) async throws -> FeedResponse {
        let q = cursor.map { "?cursor=\($0)" } ?? ""
        return try await request("/users/\(username)/posts\(q)")
    }

    func follow(username: String) async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/users/\(username)/follow", method: "POST")
    }

    func unfollow(username: String) async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/users/\(username)/follow", method: "DELETE")
    }

    func updateProfile(displayName: String?, bio: String?, isPublic: Bool?) async throws -> JuneUser {
        struct Body: Encodable { let display_name: String?; let bio: String?; let is_public: Bool? }
        struct Wrapper: Decodable { let user: JuneUser }
        let w: Wrapper = try await request("/users/me", method: "PUT",
                                           body: Body(display_name: displayName, bio: bio, is_public: isPublic))
        return w.user
    }

    // MARK: - Notifications

    func getNotifications(cursor: String? = nil) async throws -> NotificationsResponse {
        let q = cursor.map { "?cursor=\($0)" } ?? ""
        return try await request("/notifications\(q)")
    }

    func getUnreadCount() async throws -> Int {
        struct Wrapper: Decodable { let count: Int }
        let w: Wrapper = try await request("/notifications/unread-count")
        return w.count
    }

    func markAllRead() async throws {
        struct OK: Decodable { let success: Bool }
        let _: OK = try await request("/notifications/read", method: "PATCH")
    }

    // MARK: - DMs

    func getConversations() async throws -> [Conversation] {
        struct Wrapper: Decodable { let conversations: [Conversation] }
        let w: Wrapper = try await request("/dms/conversations")
        return w.conversations
    }

    func startConversation(username: String) async throws -> ConversationWrapper {
        struct Body: Encodable { let username: String }
        return try await request("/dms/conversations", method: "POST", body: Body(username: username))
    }

    func getMessages(conversationId: String, cursor: String? = nil) async throws -> MessagesResponse {
        let q = cursor.map { "?cursor=\($0)" } ?? ""
        return try await request("/dms/conversations/\(conversationId)/messages\(q)")
    }

    func sendMessage(conversationId: String, encryptedContent: String, nonce: String) async throws -> DMMessage {
        struct Body: Encodable { let encrypted_content: String; let nonce: String }
        struct Wrapper: Decodable { let message: DMMessage }
        let w: Wrapper = try await request(
            "/dms/conversations/\(conversationId)/messages",
            method: "POST",
            body: Body(encrypted_content: encryptedContent, nonce: nonce)
        )
        return w.message
    }

    // MARK: - Search

    func search(query: String, type: String = "all") async throws -> SearchResponse {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await request("/search?q=\(encoded)&type=\(type)")
    }

    func trending() async throws -> [JunePost] {
        struct Wrapper: Decodable { let posts: [JunePost] }
        let w: Wrapper = try await request("/search/trending")
        return w.posts
    }
}

// MARK: - Response types

struct FeedResponse: Decodable {
    let posts: [JunePost]
    let nextCursor: String?
    enum CodingKeys: String, CodingKey {
        case posts
        case nextCursor = "next_cursor"
    }
}

struct PostWrapper: Decodable { let post: JunePost }

struct NotificationsResponse: Decodable {
    let notifications: [JuneNotification]
    let unreadCount: Int?
    let nextCursor: String?
    enum CodingKeys: String, CodingKey {
        case notifications
        case unreadCount = "unread_count"
        case nextCursor  = "next_cursor"
    }
}

struct MessagesResponse: Decodable {
    let messages: [DMMessage]
    let nextCursor: String?
    enum CodingKeys: String, CodingKey {
        case messages
        case nextCursor = "next_cursor"
    }
}

struct ConversationWrapper: Decodable {
    let conversation: ConversationInfo
    struct ConversationInfo: Decodable {
        let id: String
        let otherUser: ConversationUser
        enum CodingKeys: String, CodingKey {
            case id
            case otherUser = "other_user"
        }
    }
}

struct SearchResponse: Decodable {
    let users: [JuneUser]?
    let posts: [JunePost]?
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL"
        case .serverError(let msg): return msg
        }
    }
}

struct APIErrorResponse: Decodable { let error: String }
