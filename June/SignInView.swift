import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        ZStack {
            AuroraBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 160)

                Text("june")
                    .font(.system(size: 92, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 2)

                Spacer()

                VStack(spacing: 12) {
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
    }

    /// Custom Apple button — calls ASAuthorizationController directly so the
    /// system sheet comes up instantly on tap, instead of going through
    /// SignInWithAppleButton's internal pipeline.
    private var appleButton: some View {
        Button {
            auth.signInWithApple()
        } label: {
            HStack {
                Image(systemName: "applelogo")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 28, alignment: .leading)
                Text("Continue with Apple")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 28)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
            )
        }
    }
}
