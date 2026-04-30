import CoreLocation
import Foundation
import WeatherKit

@MainActor
final class WeatherService: ObservableObject {
    struct Snapshot {
        var temperatureFahrenheit: Int
        var aqi: Int?
        var conditionSymbol: String
    }

    @Published var snapshot: Snapshot?

    private let service = WeatherKit.WeatherService.shared

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
        } catch {
            // Leave snapshot nil on failure; UI shows nothing rather than stale data.
        }
    }
}
