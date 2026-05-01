import MapKit
import SwiftUI

struct MapHomeView: View {
    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var cloud: CloudKitStore

    @StateObject private var weather = WeatherService()
    @StateObject private var routes = RouteController()

    @State private var cameraPosition: MapCameraPosition = .userLocation(
        fallback: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.6883, longitude: -73.9716),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    )
    @State private var sheetPresented = true
    @State private var isPitched = false
    @State private var showsTransit = true
    @State private var didFireInitialWeather = false
    @State private var selectedItem: MKMapItem?

    private static let peekDetent: PresentationDetent = .fraction(0.42)
    private static let placeDetent: PresentationDetent = .fraction(0.45)
    private static let routeDetent: PresentationDetent = .fraction(0.40)

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedItem) {
            UserAnnotation()
            if let route = routes.active?.route {
                MapPolyline(route.polyline)
                    .stroke(JuneTheme.accent, lineWidth: 6)
            }
        }
        .mapStyle(mapStyle)
        .mapControlVisibility(.hidden)
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            WeatherPill(
                temperatureFahrenheit: weather.snapshot?.temperatureFahrenheit,
                aqi: weather.snapshot?.aqi,
                conditionSymbol: weather.snapshot?.conditionSymbol
            )
            .padding(.leading, 12)
            .padding(.top, 8)
        }
        .mapItemDetailSheet(item: $selectedItem)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: 0)
        }
        .overlay(alignment: .bottomLeading) {
            LookAroundControl {
                // Look Around — wired in a follow-up
            }
            .padding(.leading, 16)
            .padding(.bottom, 16)
        }
        .overlay(alignment: .bottomTrailing) {
            MapControls(
                isPitched: $isPitched,
                showsTransit: $showsTransit,
                onLocate: { recenterOnUser() }
            )
            .padding(.trailing, 12)
            .padding(.bottom, 16)
        }
        .task {
            location.requestAuthorization()
            location.startUpdates()
            await cloud.loadAll()
            if !didFireInitialWeather {
                didFireInitialWeather = true
                let seed = location.currentLocation
                    ?? CLLocation(latitude: 40.6883, longitude: -73.9716)
                await weather.refresh(for: seed)
            }
        }
        .onChange(of: location.currentLocation) { _, newValue in
            guard let newValue else { return }
            Task { await weather.refresh(for: newValue) }
        }
        .onChange(of: routes.active) { _, newValue in
            guard let newValue else { return }
            // Fit camera to the route once it's ready.
            withAnimation(.easeInOut(duration: 0.6)) {
                cameraPosition = .rect(newValue.route.polyline.boundingMapRect)
            }
        }
        // Yield the home-sheet slot when a POI is tapped so mapItemDetailSheet
        // (Apple's draggable place card) can take over. When the user dismisses
        // the place card, selectedItem flips back to nil and the home sheet
        // returns.
        .sheet(isPresented: Binding(
            get: { sheetPresented && selectedItem == nil },
            set: { sheetPresented = $0 }
        )) {
            Group {
                if routes.active != nil {
                    RouteSheet { endRoute() }
                } else {
                    HomeSheet(selectedItem: $selectedItem)
                }
            }
            .environmentObject(routes)
            .presentationDetents(currentDetents)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationCornerRadius(28)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
    }

    private var currentDetents: Set<PresentationDetent> {
        if routes.active != nil {
            return [Self.routeDetent, .medium, .large]
        } else {
            return [Self.peekDetent, .medium, .large]
        }
    }

    private var mapStyle: MapStyle {
        .standard(
            elevation: isPitched ? .realistic : .flat,
            pointsOfInterest: .all,
            showsTraffic: false
        )
    }

    private func recenterOnUser() {
        withAnimation(.easeInOut(duration: 0.4)) {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }

    private func endRoute() {
        routes.cancel()
        selectedItem = nil
        recenterOnUser()
    }
}
