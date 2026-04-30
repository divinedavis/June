import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var comingSoonProvider: String?
    @State private var showingEmailAuth = false

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                Spacer().frame(height: 160)

                Text("june")
                    .font(.system(size: 92, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 2)

                Spacer()

                VStack(spacing: 12) {
                    providerButton(
                        label: "Continue with email",
                        systemImage: "envelope"
                    ) {
                        showingEmailAuth = true
                    }

                    appleButton

                    if let message = auth.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 56)
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingEmailAuth) {
            EmailAuthView()
                .presentationDragIndicator(.visible)
        }
        .alert(item: $comingSoonProvider.asAlertItem) { item in
            Alert(
                title: Text("Coming soon"),
                message: Text("\(item.value.capitalized) sign-in is on the way. For now, use Continue with Apple."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var backdrop: some View {
        ZStack(alignment: .top) {
            Image("AuthBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 360)
            .ignoresSafeArea()

            // Soft fade at the bottom so the buttons read against the trees.
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
            }
            .ignoresSafeArea()
        }
    }

    private func providerButton(label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, alignment: .leading)
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 28)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
            )
        }
    }

    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                auth.handle(authorization: authorization)
            case .failure(let error):
                if (error as? ASAuthorizationError)?.code != .canceled {
                    auth.errorMessage = error.localizedDescription
                }
            }
        }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Helpers

private struct AlertItem: Identifiable {
    let value: String
    var id: String { value }
}

private extension Binding where Value == String? {
    var asAlertItem: Binding<AlertItem?> {
        Binding<AlertItem?>(
            get: { wrappedValue.map { AlertItem(value: $0) } },
            set: { newValue in wrappedValue = newValue?.value }
        )
    }
}
