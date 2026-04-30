import SwiftUI

struct MapControls: View {
    @Binding var isPitched: Bool
    @Binding var showsTransit: Bool
    let onLocate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            controlButton(label: "3D", isActive: isPitched) {
                isPitched.toggle()
            }
            divider
            controlButton(systemImage: "tram.fill", isActive: showsTransit) {
                showsTransit.toggle()
            }
            divider
            controlButton(systemImage: "location.north.fill", isActive: false) {
                onLocate()
            }
        }
        .frame(width: 48)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(JuneTheme.controlBackground)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(height: 0.5)
    }

    @ViewBuilder
    private func controlButton(systemImage: String? = nil, label: String? = nil, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                }
                if let label {
                    Text(label)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(isActive ? JuneTheme.accent : .white)
            .frame(width: 48, height: 48)
        }
    }
}

struct LookAroundControl: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "binoculars.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(Color(red: 0.1, green: 0.07, blue: 0.18))
                )
        }
    }
}
