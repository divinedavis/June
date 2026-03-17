import Foundation

// MARK: - User

struct JuneUser: Codable, Identifiable, Equatable {
    let id: String
    var username: String
    var email: String?
    var displayName: String
    var bio: String?
    var avatarUrl: String?
    var isPublic: Bool
    var followerCount: Int
    var followingCount: Int
    var postCount: Int
    var publicKey: String?
    var isFollowing: Bool?
    var isFollower: Bool?
    var canView: Bool?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email, bio
        case displayName  = "display_name"
        case avatarUrl    = "avatar_url"
        case isPublic     = "is_public"
        case followerCount  = "follower_count"
        case followingCount = "following_count"
        case postCount    = "post_count"
        case publicKey    = "public_key"
        case isFollowing  = "is_following"
        case isFollower   = "is_follower"
        case canView      = "can_view"
        case createdAt    = "created_at"
    }

    var initials: String {
        let name = displayName.isEmpty ? username : displayName
        return String(name.prefix(1)).uppercased()
    }
}

// MARK: - Post

struct JunePost: Codable, Identifiable, Equatable {
    let id: String
    var content: String
    var mediaUrl: String?
    var likeCount: Int
    var repostCount: Int
    var replyCount: Int
    var viewCount: Int
    var createdAt: String
    var replyToId: String?
    var repostOfId: String?
    var user: PostUser
    var isLiked: Bool
    var isReposted: Bool

    enum CodingKeys: String, CodingKey {
        case id, content, user
        case mediaUrl    = "media_url"
        case likeCount   = "like_count"
        case repostCount = "repost_count"
        case replyCount  = "reply_count"
        case viewCount   = "view_count"
        case createdAt   = "created_at"
        case replyToId   = "reply_to_id"
        case repostOfId  = "repost_of_id"
        case isLiked     = "is_liked"
        case isReposted  = "is_reposted"
    }

    var timeAgo: String { createdAt.timeAgo }
}

struct PostUser: Codable, Equatable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl   = "avatar_url"
        case isPublic    = "is_public"
    }

    var initials: String { String(displayName.prefix(1)).uppercased() }
}

// MARK: - Notification

struct JuneNotification: Codable, Identifiable {
    let id: String
    let type: String
    let postId: String?
    var read: Bool
    let createdAt: String
    let fromUser: NotificationUser

    enum CodingKeys: String, CodingKey {
        case id, type, read
        case postId    = "post_id"
        case createdAt = "created_at"
        case fromUser  = "from_user"
    }

    var timeAgo: String { createdAt.timeAgo }

    var actionText: String {
        switch type {
        case "like":    return "liked your post"
        case "repost":  return "reposted your post"
        case "follow":  return "followed you"
        case "reply":   return "replied to your post"
        case "mention": return "mentioned you"
        default:        return "interacted with you"
        }
    }

    var iconName: String {
        switch type {
        case "like":    return "heart.fill"
        case "repost":  return "repeat"
        case "follow":  return "person.fill.badge.plus"
        case "reply":   return "bubble.left.fill"
        case "mention": return "at"
        default:        return "bell.fill"
        }
    }

    var iconColor: String {
        switch type {
        case "like":    return "E0245E"
        case "repost":  return "00BA7C"
        case "follow":  return "E8A020"
        default:        return "E8A020"
        }
    }
}

struct NotificationUser: Codable {
    let id: String?
    let username: String?
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl   = "avatar_url"
    }
}

// MARK: - DMs

struct Conversation: Codable, Identifiable {
    let id: String
    var lastMessageAt: String?
    let createdAt: String?
    let otherUser: ConversationUser
    var lastMessageEncrypted: String?
    var lastMessageTime: String?

    enum CodingKeys: String, CodingKey {
        case id
        case lastMessageAt        = "last_message_at"
        case createdAt            = "created_at"
        case otherUser            = "other_user"
        case lastMessageEncrypted = "last_message_encrypted"
        case lastMessageTime      = "last_message_time"
    }
}

struct ConversationUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let publicKey: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl   = "avatar_url"
        case publicKey   = "public_key"
    }

    var initials: String { String((displayName ?? username).prefix(1)).uppercased() }
}

struct DMMessage: Codable, Identifiable {
    let id: String
    let encryptedContent: String
    let nonce: String
    let createdAt: String
    let sender: DMSender
    var decryptedContent: String?

    enum CodingKeys: String, CodingKey {
        case id
        case encryptedContent = "encrypted_content"
        case nonce
        case createdAt        = "created_at"
        case sender
    }

    var timeAgo: String { createdAt.timeAgo }
}

struct DMSender: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl   = "avatar_url"
    }
}

// MARK: - Auth Responses

struct AuthResponse: Codable {
    let user: JuneUser
    let token: String
}

// MARK: - String extension

extension String {
    var timeAgo: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: self) ?? Date()
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(diff / 60)m" }
        if diff < 86400 { return "\(diff / 3600)h" }
        if diff < 604800 { return "\(diff / 86400)d" }
        let cal = Calendar.current
        let components = cal.dateComponents([.month, .day], from: date)
        let months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let m = Calendar.current.component(.month, from: date) - 1
        return "\(months[m]) \(components.day ?? 1)"
    }
}
