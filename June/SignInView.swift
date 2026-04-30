import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.04), Color(white: 0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "map.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(JuneTheme.accent)

                VStack(spacing: 8) {
                    Text("June")
                        .font(.system(size: 44, weight: .bold))
                    Text("All your favorite places\nfrom around the world.")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

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
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 24)

                if let message = auth.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 24)
                }

                Text("By continuing you agree to use June responsibly.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 16)
            }
        }
    }
}
