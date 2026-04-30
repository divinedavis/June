import MapKit
import SwiftUI

struct RouteSheet: View {
    @EnvironmentObject private var routes: RouteController

    let onEnd: () -> Void

    var body: some View {
        if let active = routes.active {
            VStack(alignment: .leading, spacing: 0) {
                header(for: active)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                summaryRow(for: active)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)

                stepsList(for: active.route)
                    .padding(.top, 16)

                Spacer(minLength: 0)
            }
            .background(JuneTheme.sheetBackground)
        } else {
            EmptyView()
        }
    }

    // MARK: - Header

    private func header(for active: RouteController.ActiveRoute) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Directions to")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(active.destination.name ?? "Destination")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Button(action: onEnd) {
                Text("End")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.85)))
            }
        }
    }

    private func summaryRow(for active: RouteController.ActiveRoute) -> some View {
        HStack(spacing: 12) {
            metaPill(icon: transportIcon(active.transport), text: formatDuration(active.route.expectedTravelTime))
            metaPill(icon: "ruler", text: formatDistance(active.route.distance))
            Spacer()
        }
    }

    // MARK: - Steps

    private func stepsList(for route: MKRoute) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(route.steps.enumerated()), id: \.offset) { index, step in
                    if !step.instructions.isEmpty {
                        StepRow(step: step, isFirst: index == 0)
                        if index < route.steps.count - 1 {
                            Divider().background(.white.opacity(0.06))
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(white: 0.13))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Helpers

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.10)))
    }

    private func transportIcon(_ transport: MKDirectionsTransportType) -> String {
        switch transport {
        case .walking: return "figure.walk"
        case .transit: return "tram.fill"
        default: return "car.fill"
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        if mins < 60 { return "\(mins) min" }
        let h = mins / 60, m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func formatDistance(_ meters: CLLocationDistance) -> String {
        let miles = meters / 1609.34
        if miles < 0.1 {
            let feet = Int(meters * 3.28084)
            return "\(feet) ft"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return "\(Int(miles)) mi"
        }
    }
}

private struct StepRow: View {
    let step: MKRoute.Step
    let isFirst: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color(white: 0.22)).frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(step.instructions)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                if step.distance > 0 {
                    Text(formattedDistance)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var icon: String {
        if isFirst { return "location.fill" }
        let lower = step.instructions.lowercased()
        if lower.contains("left") { return "arrow.turn.up.left" }
        if lower.contains("right") { return "arrow.turn.up.right" }
        if lower.contains("merge") { return "arrow.merge" }
        if lower.contains("arrive") || lower.contains("destination") { return "flag.checkered" }
        return "arrow.up"
    }

    private var formattedDistance: String {
        let miles = step.distance / 1609.34
        if miles < 0.1 {
            return "\(Int(step.distance * 3.28084)) ft"
        }
        return String(format: "%.1f mi", miles)
    }
}
