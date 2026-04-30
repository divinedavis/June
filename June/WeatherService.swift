import CoreLocation
import Foundation
import os
import WeatherKit

@MainActor
final class WeatherService: ObservableObject {
    struct Snapshot {
        var temperatureFahrenheit: Int
        var aqi: Int?
        var conditionSymbol: String
    }

    @Published var snapshot: Snapshot?
    @Published var lastError: String?

    private let service = WeatherKit.WeatherService.shared
    private let log = Logger(subsystem: "com.divinedavis.june", category: "WeatherService")

    func refresh(for location: CLLocation) async {
        do {
            let weather = try await service.weather(for: location)
            let tempF = Int(weather.currentWeather.temperature.converted(to: .fahrenheit).value.rounded())
            let symbol = weather.currentWeather.symbolName
            snapshot = Snapshot(
                temperatureFahrenheit: tempF,
                aqi: nil,
                conditionSymbol: symbol
            )
            lastError = nil
            log.info("WeatherKit OK: \(tempF)°F (\(symbol))")
        } catch {
            // WeatherKit can take up to ~24h to fully provision after first enabling
            // the capability, and the framework throws opaque errors when it can't
            // authenticate. Surface to Console + lastError; keep the previous
            // snapshot rather than nil so the UI doesn't flicker between values.
            log.error("WeatherKit failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }
}
