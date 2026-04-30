import CoreLocation
import Foundation

// v1: placeholder-only store. CloudKit is deliberately not wired because the
// bundle-id ↔ iCloud-container association couldn't be persisted server-side
// (see project_june.md). Constructing CKContainer(identifier:) without the
// matching entitlement traps on device, which is what crashed TestFlight 1.0
// (6) on launch. v1.1 will restore live CloudKit syncing once the container
// linkage is sorted out.
@MainActor
final class CloudKitStore: ObservableObject {
    @Published var favorites: [Favorite] = Favorite.placeholders
    @Published var recents: [RecentPlace] = RecentPlace.placeholders
    @Published var profile: UserProfile = UserProfile()

    func loadAll() async {
        // No-op until CloudKit is restored. Placeholders remain.
    }

    func saveFavorite(_ favorite: Favorite) async {
        if let i = favorites.firstIndex(where: { $0.id == favorite.id }) {
            favorites[i] = favorite
        } else {
            favorites.append(favorite)
        }
    }

    func recordRecent(_ place: RecentPlace) async {
        recents.removeAll { $0.id == place.id }
        recents.insert(place, at: 0)
        if recents.count > 25 { recents.removeLast(recents.count - 25) }
    }

    func saveProfile(displayName: String?, pictureData: Data?) async {
        profile = UserProfile(displayName: displayName, profilePictureData: pictureData)
    }
}
