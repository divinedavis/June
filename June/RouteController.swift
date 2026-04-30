import CoreLocation
import MapKit
import SwiftUI

/// Owns the currently-active in-app route. MapHomeView observes this to draw
/// the polyline + fit the camera; RouteSheet observes it to render the step
/// list. PlaceDetailView's Directions tile asks for one to start.
@MainActor
final class RouteController: ObservableObject {
    struct ActiveRoute: Equatable {
        let destination: MKMapItem
        let route: MKRoute
        let transport: MKDirectionsTransportType

        static func == (lhs: ActiveRoute, rhs: ActiveRoute) -> Bool {
            lhs.destination === rhs.destination && lhs.route === rhs.route && lhs.transport == rhs.transport
        }
    }

    @Published var active: ActiveRoute?
    @Published var loading = false
    @Published var lastError: String?

    func start(to destination: MKMapItem, from origin: CLLocationCoordinate2D, transport: MKDirectionsTransportType) async {
        loading = true
        lastError = nil
        defer { loading = false }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = destination
        request.transportType = transport
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()
            if let route = response.routes.first {
                active = ActiveRoute(destination: destination, route: route, transport: transport)
            } else {
                lastError = "No route found"
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func cancel() {
        active = nil
    }
}
