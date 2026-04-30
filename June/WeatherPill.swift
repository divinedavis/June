import SwiftUI

struct WeatherPill: View {
    let temperatureFahrenheit: Int?
    let aqi: Int?
    let conditionSymbol: String?

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: conditionSymbol ?? "cloud.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
            if let temperatureFahrenheit {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(temperatureFahrenheit)°")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    if let aqi {
                        HStack(spacing: 4) {
                            Text("AQI \(aqi)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.85))
                            Circle()
                                .fill(aqiColor(aqi))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(JuneTheme.pillBackground)
        )
    }

    private func aqiColor(_ value: Int) -> Color {
        switch value {
        case ..<51: return .green
        case ..<101: return .yellow
        case ..<151: return .orange
        case ..<201: return .red
        default: return .purple
        }
    }
}

#Preview {
    WeatherPill(temperatureFahrenheit: 50, aqi: 49, conditionSymbol: "cloud.fill")
        .padding()
        .background(.black)
}
