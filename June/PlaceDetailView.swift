import MapKit
import SwiftUI
import UIKit

struct PlaceDetailView: View {
    let item: MKMapItem
    let onDismiss: () -> Void

    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var cloud: CloudKitStore
    @EnvironmentObject private var routes: RouteController

    @State private var walkMinutes: Int?
    @State private var driveMinutes: Int?
    @State private var loaded = false
    @State private var requestingDirections = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)

            metaRow
                .padding(.horizontal, 20)
                .padding(.top, 8)

            actions
                .padding(.horizontal, 16)
                .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .background(JuneTheme.sheetBackground)
        .task(id: item.placemark.coordinate.latitude) {
            guard !loaded else { return }
            loaded = true
            await Task.detached(priority: .userInitiated) {
                await self.loadTravelTimes()
            }.value
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name ?? "Selected place")
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
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
                    .background(Circle().fill(.black.opacity(0.4)))
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 14) {
            if let walkMinutes {
                metaPill(icon: "figure.walk", text: "\(walkMinutes) min walk")
            }
            if let driveMinutes {
                metaPill(icon: "car.fill", text: "\(driveMinutes) min drive")
            }
            if walkMinutes == nil && driveMinutes == nil && loaded {
                metaPill(icon: "location.slash", text: "ETA unavailable")
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            actionTile(icon: "arrow.triangle.turn.up.right.circle.fill", label: "Directions", loading: requestingDirections) {
                Task { await startDirections() }
            }
            if item.phoneNumber != nil {
                actionTile(icon: "phone.fill", label: "Call") { call() }
            }
            if item.url != nil {
                actionTile(icon: "globe", label: "Website") { openWebsite() }
            }
            actionTile(icon: "map", label: "Open in Maps") { openInAppleMaps(driving: true) }
        }
    }

    // MARK: - Building blocks

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.10)))
    }

    private func actionTile(icon: String, label: String, loading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if loading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.10))
            )
        }
        .disabled(loading)
    }

    // MARK: - Data

    private var subtitleText: String? {
        // Use placemark address fragments — name itself is in the title.
        let placemark = item.placemark
        let pieces = [placemark.subThoroughfare, placemark.thoroughfare, placemark.locality]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return pieces.isEmpty ? placemark.title : pieces.joined(separator: " ")
    }

    @MainActor
    private func loadTravelTimes() async {
        await Task.yield()
        let coordinate = item.placemark.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }

        guard let here = location.currentLocation else { return }
        let source = MKMapItem(placemark: MKPlacemark(coordinate: here.coordinate))

        async let walking = travelTime(from: source, to: item, transport: .walking)
        async let driving = travelTime(from: source, to: item, transport: .automobile)
        let (walk, drive) = await (walking, driving)

        await MainActor.run {
            self.walkMinutes = walk
            self.driveMinutes = drive

            // Record this place as a Recent so it shows up in the home sheet later.
            let recent = RecentPlace(
                id: "\(coordinate.latitude),\(coordinate.longitude)",
                name: item.name ?? "Place",
                origin: "From My Location",
                coordinate: coordinate
            )
            Task { await cloud.recordRecent(recent) }
        }
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

    // MARK: - Actions

    private func startDirections() async {
        guard let here = location.currentLocation else {
            // No location yet — fall back to Apple Maps so the user gets *something*.
            openInAppleMaps(driving: true)
            return
        }
        requestingDirections = true
        await routes.start(to: item, from: here.coordinate, transport: .automobile)
        requestingDirections = false
    }

    private func openInAppleMaps(driving: Bool) {
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: driving ? MKLaunchOptionsDirectionsModeDriving : MKLaunchOptionsDirectionsModeWalking
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
        let url = "http://maps.apple.com/?ll=\(item.placemark.coordinate.latitude),\(item.placemark.coordinate.longitude)&q=\(item.name?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let shareURL = URL(string: url) else { return }
        let av = UIActivityViewController(activityItems: [item.name ?? "Place", shareURL], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
            .first?.rootViewController?
            .present(av, animated: true)
    }
}
