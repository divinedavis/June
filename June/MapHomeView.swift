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

    var body: some View {
        Map(position: $cameraPosition) {
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
        .overlay(alignment: .bottomLeading) {
            LookAroundControl {
                // Look Around — wired in a follow-up
            }
            .padding(.leading, 16)
            .padding(.bottom, 360)
        }
        .overlay(alignment: .trailing) {
            MapControls(
                isPitched: $isPitched,
                showsTransit: $showsTransit,
                onLocate: { recenterOnUser() }
            )
            .padding(.trailing, 12)
            .padding(.bottom, 360)
        }
        .task {
            location.requestAuthorization()
            location.startUpdates()
            await cloud.loadAll()
        }
        .onChange(of: location.currentLocation) { _, newValue in
            guard let newValue else { return }
            Task { await weather.refresh(for: newValue) }
        }
        .sheet(isPresented: $sheetPresented) {
            HomeSheet()
                .presentationDetents([.fraction(0.18), .medium, .large])
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
