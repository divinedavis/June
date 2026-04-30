import CoreLocation
import Foundation

struct Favorite: Identifiable, Hashable {
    enum Kind: String, CaseIterable {
        case home, work, transit, custom

        var systemImage: String {
            switch self {
            case .home: return "house.fill"
            case .work: return "briefcase.fill"
            case .transit: return "tram.fill"
            case .custom: return "mappin"
            }
        }
    }

    let id: String
    var name: String
    var subtitle: String
    var kind: Kind
    var coordinate: CLLocationCoordinate2D?

    static let placeholders: [Favorite] = [
        Favorite(id: "home", name: "Home", subtitle: "Close by", kind: .home, coordinate: nil),
        Favorite(id: "transit", name: "Transit", subtitle: "Nearby", kind: .transit, coordinate: nil),
        Favorite(id: "work", name: "Work", subtitle: "37 min", kind: .work, coordinate: nil),
        Favorite(id: "custom", name: "Five Man…", subtitle: "4.7 mi", kind: .custom, coordinate: nil)
    ]
}

extension Favorite.Kind {
    var pillTint: String {
        switch self {
        case .home: return "homeIcon"
        case .transit: return "transitIcon"
        case .work: return "workIcon"
        case .custom: return "pinIcon"
        }
    }
}

struct RecentPlace: Identifiable, Hashable {
    let id: String
    var name: String
    var origin: String
    var coordinate: CLLocationCoordinate2D?

    static let placeholders: [RecentPlace] = [
        RecentPlace(id: "halsey", name: "22 Halsey Street #2A, Brooklyn", origin: "From My Location", coordinate: nil)
    ]
}

extension CLLocationCoordinate2D: Equatable, Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

struct UserProfile: Hashable {
    var displayName: String?
    var profilePictureData: Data?
}
