import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var showingEmailAuth = false

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
                    emailButton
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
    }

    private var emailButton: some View {
        Button {
            showingEmailAuth = true
        } label: {
            HStack {
                Image(systemName: "envelope")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 28, alignment: .leading)
                Text("Continue with email")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 28)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
            )
        }
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
