import MapKit
import SwiftUI
import UIKit

/// Custom draggable bottom sheet for POI interactions. Replaces Apple's stock
/// mapItemDetailSheet so we keep full control over content (in-app directions,
/// June's design language) and the user gets the pull-up / pull-down behavior
/// inherited from the parent .sheet's presentationDetents.
struct PlaceDetailSheet: View {
    let item: MKMapItem
    let onDismiss: () -> Void
    let onDirections: () -> Void

    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var cloud: CloudKitStore

    @State private var walkMinutes: Int?
    @State private var driveMinutes: Int?
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var bookmarked = false
    @State private var detailsLoaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                hero
                travelPills
                actions
                if let phone = item.phoneNumber {
                    infoRow(icon: "phone.fill", title: "Phone", value: phone) { call() }
                }
                if let url = item.url {
                    infoRow(icon: "globe", title: "Website", value: url.absoluteString) { openWebsite() }
                }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
        .background(JuneTheme.sheetBackground)
        .task(id: itemKey) { await loadDetails() }
    }

    private var itemKey: String {
        let c = item.placemark.coordinate
        return "\(c.latitude),\(c.longitude)"
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name ?? "Place")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                iconCapsule(systemName: bookmarked ? "bookmark.fill" : "bookmark") {
                    bookmarked.toggle()
                    Task { await saveBookmark() }
                }
                iconCapsule(systemName: "square.and.arrow.up") { share() }
                iconCapsule(systemName: "xmark", action: onDismiss)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Hero

    @ViewBuilder
    private var hero: some View {
        ZStack {
            if let lookAroundScene {
                LookAroundPreview(initialScene: lookAroundScene, allowsNavigation: false, showsRoadLabels: true)
                    .transition(.opacity)
            } else {
                LinearGradient(
                    colors: heroGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                )
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Travel pills

    private var travelPills: some View {
        HStack(spacing: 10) {
            if let walkMinutes {
                metaPill(text: "\(walkMinutes) min walk", systemImage: "figure.walk")
            }
            if let driveMinutes {
                metaPill(text: "\(driveMinutes) min drive", systemImage: "car.fill")
            }
            if walkMinutes == nil && driveMinutes == nil && detailsLoaded {
                metaPill(text: "ETA unavailable", systemImage: "location.slash")
            }
            Spacer()
        }
    }

    // MARK: - Action tiles

    private var actions: some View {
        HStack(spacing: 8) {
            actionTile(label: "Directions", icon: "arrow.triangle.turn.up.right.circle.fill") {
                onDirections()
            }
            if item.phoneNumber != nil {
                actionTile(label: "Call", icon: "phone.fill") { call() }
            }
            if item.url != nil {
                actionTile(label: "Website", icon: "globe") { openWebsite() }
            }
            actionTile(label: "Apple Maps", icon: "map") { openInMaps() }
        }
    }

    private func infoRow(icon: String, title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(JuneTheme.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
        }
    }

    // MARK: - Building blocks

    private func iconCapsule(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white.opacity(0.10)))
        }
    }

    private func metaPill(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.10)))
    }

    private func actionTile(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.10))
            )
        }
    }

    // MARK: - Data + computed

    private var subtitleText: String? {
        let placemark = item.placemark
        let pieces = [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return pieces.isEmpty ? placemark.title : pieces.joined(separator: " ")
    }

    private var heroGradient: [Color] { [categoryPalette.start, categoryPalette.end] }

    private struct CategoryPalette {
        let start: Color
        let end: Color
    }

    private var categoryPalette: CategoryPalette {
        guard let category = item.pointOfInterestCategory else {
            return CategoryPalette(start: Color(red: 0.22, green: 0.28, blue: 0.42), end: Color(red: 0.10, green: 0.14, blue: 0.22))
        }
        switch category {
        case .restaurant, .foodMarket, .bakery, .cafe:
            return CategoryPalette(start: Color(red: 0.74, green: 0.36, blue: 0.20), end: Color(red: 0.34, green: 0.16, blue: 0.10))
        case .park, .nationalPark, .beach:
            return CategoryPalette(start: Color(red: 0.30, green: 0.62, blue: 0.40), end: Color(red: 0.10, green: 0.30, blue: 0.18))
        case .nightlife, .theater, .movieTheater:
            return CategoryPalette(start: Color(red: 0.50, green: 0.22, blue: 0.62), end: Color(red: 0.18, green: 0.08, blue: 0.30))
        case .museum, .library, .school, .university:
            return CategoryPalette(start: Color(red: 0.30, green: 0.36, blue: 0.62), end: Color(red: 0.10, green: 0.14, blue: 0.30))
        case .hospital, .pharmacy:
            return CategoryPalette(start: Color(red: 0.74, green: 0.30, blue: 0.36), end: Color(red: 0.30, green: 0.10, blue: 0.16))
        default:
            return CategoryPalette(start: Color(red: 0.22, green: 0.28, blue: 0.42), end: Color(red: 0.10, green: 0.14, blue: 0.22))
        }
    }

    private var categoryIcon: String {
        guard let category = item.pointOfInterestCategory else { return "mappin" }
        switch category {
        case .restaurant, .foodMarket, .bakery, .cafe: return "fork.knife"
        case .park, .nationalPark: return "leaf.fill"
        case .beach: return "beach.umbrella.fill"
        case .museum: return "building.columns.fill"
        case .school, .university: return "graduationcap.fill"
        case .hospital, .pharmacy: return "cross.fill"
        case .hotel: return "bed.double.fill"
        case .gasStation: return "fuelpump.fill"
        case .parking: return "p.square.fill"
        case .publicTransport: return "tram.fill"
        case .airport: return "airplane"
        case .stadium: return "sportscourt.fill"
        case .theater, .movieTheater: return "theatermasks.fill"
        case .store: return "bag.fill"
        case .nightlife: return "wineglass.fill"
        case .fitnessCenter: return "figure.run"
        case .library: return "books.vertical.fill"
        case .atm, .bank: return "dollarsign.circle.fill"
        default: return "mappin"
        }
    }

    @MainActor
    private func loadDetails() async {
        async let look: () = loadLookAround()
        async let times: () = loadTravelTimes()
        _ = await (look, times)
        detailsLoaded = true
        await recordRecent()
    }

    @MainActor
    private func loadLookAround() async {
        let coordinate = item.placemark.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        let request = MKLookAroundSceneRequest(coordinate: coordinate)
        if let scene = try? await request.scene {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.lookAroundScene = scene
            }
        }
    }

    @MainActor
    private func loadTravelTimes() async {
        guard let here = location.currentLocation else { return }
        let source = MKMapItem(placemark: MKPlacemark(coordinate: here.coordinate))

        async let walking = travelTime(from: source, to: item, transport: .walking)
        async let driving = travelTime(from: source, to: item, transport: .automobile)
        let (walk, drive) = await (walking, driving)

        self.walkMinutes = walk
        self.driveMinutes = drive
    }

    private func travelTime(from source: MKMapItem, to dest: MKMapItem, transport: MKDirectionsTransportType) async -> Int? {
        let request = MKDirections.Request()
        request.source = source
        request.destination = dest
        request.transportType = transport
        guard let response = try? await MKDirections(request: request).calculate(),
              let route = response.routes.first else {
            return nil
        }
        return Int(route.expectedTravelTime / 60)
    }

    private func recordRecent() async {
        let coord = item.placemark.coordinate
        let recent = RecentPlace(
            id: "\(coord.latitude),\(coord.longitude)",
            name: item.name ?? "Place",
            origin: "From My Location",
            coordinate: coord
        )
        await cloud.recordRecent(recent)
    }

    private func saveBookmark() async {
        let coord = item.placemark.coordinate
        let recent = RecentPlace(
            id: "\(coord.latitude),\(coord.longitude)",
            name: item.name ?? "Place",
            origin: "Saved",
            coordinate: coord
        )
        await cloud.recordRecent(recent)
    }

    // MARK: - Actions

    private func openInMaps() {
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func call() {
        guard let phone = item.phoneNumber else { return }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel:\(digits)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func openWebsite() {
        guard let url = item.url else { return }
        UIApplication.shared.open(url)
    }

    private func share() {
        let coord = item.placemark.coordinate
        let mapsURL = "http://maps.apple.com/?ll=\(coord.latitude),\(coord.longitude)&q=\(item.name?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: mapsURL) else { return }
        let av = UIActivityViewController(activityItems: [item.name ?? "Place", url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
            .first?.rootViewController?
            .present(av, animated: true)
    }
}
