import MapKit
import SwiftUI

struct MapHomeView: View {
    @EnvironmentObject private var location: LocationManager
    @EnvironmentObject private var cloud: CloudKitStore

    @StateObject private var weather = WeatherService()
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

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedItem) {
            UserAnnotation()
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Reserve space for the peek detent so map controls float above the sheet.
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
            // Weather may not be wired up to a location yet on first launch.
            // Try whatever we have, and a Brooklyn fallback if nothing yet.
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
        .sheet(isPresented: $sheetPresented) {
            Group {
                if let selectedItem {
                    PlaceDetailView(item: selectedItem) {
                        self.selectedItem = nil
                    }
                } else {
                    HomeSheet(selectedItem: $selectedItem)
                }
            }
            .presentationDetents(
                selectedItem == nil
                    ? [Self.peekDetent, .medium, .large]
                    : [Self.placeDetent, .medium, .large]
            )
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationCornerRadius(28)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
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
            cameraPosition = .userLocation(
                fallback: .automatic
            )
        }
    }
}
