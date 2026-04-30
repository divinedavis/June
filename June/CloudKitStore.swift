import CloudKit
import CoreLocation
import Foundation

@MainActor
final class CloudKitStore: ObservableObject {
    @Published var favorites: [Favorite] = Favorite.placeholders
    @Published var recents: [RecentPlace] = RecentPlace.placeholders
    @Published var profile: UserProfile = UserProfile()

    private let container = CKContainer(identifier: "iCloud.com.divinedavis.june")
    private var database: CKDatabase { container.privateCloudDatabase }

    private enum RecordType {
        static let favorite = "Favorite"
        static let recent = "RecentPlace"
        static let profile = "UserProfile"
    }

    func loadAll() async {
        async let favs: () = loadFavorites()
        async let recs: () = loadRecents()
        async let prof: () = loadProfile()
        _ = await (favs, recs, prof)
    }

    func loadFavorites() async {
        do {
            let query = CKQuery(recordType: RecordType.favorite, predicate: NSPredicate(value: true))
            let (matched, _) = try await database.records(matching: query)
            let parsed = matched.compactMap { _, result -> Favorite? in
                guard case .success(let record) = result else { return nil }
                return Self.favorite(from: record)
            }
            if !parsed.isEmpty { favorites = parsed }
        } catch {
            // Keep placeholders on failure (e.g., user hasn't signed in to iCloud yet).
        }
    }

    func loadRecents() async {
        do {
            let query = CKQuery(recordType: RecordType.recent, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let (matched, _) = try await database.records(matching: query, resultsLimit: 25)
            let parsed = matched.compactMap { _, result -> RecentPlace? in
                guard case .success(let record) = result else { return nil }
                return Self.recent(from: record)
            }
            if !parsed.isEmpty { recents = parsed }
        } catch {
            // Keep placeholders on failure.
        }
    }

    func loadProfile() async {
        do {
            let query = CKQuery(recordType: RecordType.profile, predicate: NSPredicate(value: true))
            let (matched, _) = try await database.records(matching: query, resultsLimit: 1)
            if case .success(let record) = matched.first?.1 {
                let name = record["displayName"] as? String
                var pictureData: Data?
                if let asset = record["profilePicture"] as? CKAsset, let url = asset.fileURL {
                    pictureData = try? Data(contentsOf: url)
                }
                profile = UserProfile(displayName: name, profilePictureData: pictureData)
            }
        } catch {
            // Profile stays empty on first launch.
        }
    }

    func saveFavorite(_ favorite: Favorite) async {
        let record = CKRecord(recordType: RecordType.favorite, recordID: CKRecord.ID(recordName: favorite.id))
        record["name"] = favorite.name as CKRecordValue
        record["subtitle"] = favorite.subtitle as CKRecordValue
        record["kind"] = favorite.kind.rawValue as CKRecordValue
        if let coordinate = favorite.coordinate {
            record["location"] = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        _ = try? await database.save(record)
    }

    func recordRecent(_ place: RecentPlace) async {
        let record = CKRecord(recordType: RecordType.recent, recordID: CKRecord.ID(recordName: place.id))
        record["name"] = place.name as CKRecordValue
        record["origin"] = place.origin as CKRecordValue
        if let coordinate = place.coordinate {
            record["location"] = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        _ = try? await database.save(record)
        await loadRecents()
    }

    func saveProfile(displayName: String?, pictureData: Data?) async {
        let recordID = CKRecord.ID(recordName: "userProfile")
        let record = (try? await database.record(for: recordID)) ?? CKRecord(recordType: RecordType.profile, recordID: recordID)
        record["displayName"] = displayName as CKRecordValue?
        if let data = pictureData {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("profile-\(UUID().uuidString).jpg")
            try? data.write(to: url)
            record["profilePicture"] = CKAsset(fileURL: url)
        }
        _ = try? await database.save(record)
        profile = UserProfile(displayName: displayName, profilePictureData: pictureData)
    }

    private static func favorite(from record: CKRecord) -> Favorite? {
        guard let name = record["name"] as? String,
              let subtitle = record["subtitle"] as? String,
              let kindRaw = record["kind"] as? String,
              let kind = Favorite.Kind(rawValue: kindRaw) else { return nil }
        let location = record["location"] as? CLLocation
        return Favorite(
            id: record.recordID.recordName,
            name: name,
            subtitle: subtitle,
            kind: kind,
            coordinate: location?.coordinate
        )
    }

    private static func recent(from record: CKRecord) -> RecentPlace? {
        guard let name = record["name"] as? String,
              let origin = record["origin"] as? String else { return nil }
        let location = record["location"] as? CLLocation
        return RecentPlace(
            id: record.recordID.recordName,
            name: name,
            origin: origin,
            coordinate: location?.coordinate
        )
    }
}
