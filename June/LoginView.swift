import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var auth
    @State private var loginInput = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.juneBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Logo
                        VStack(spacing: 14) {
                            FalconLogo(size: 72)
                            Text("June")
                                .font(.system(size: 38, weight: .bold, design: .default))
                                .foregroundStyle(Color.juneTextPrimary)
                            Text("All your news at your fingertips")
                                .font(.subheadline)
                                .foregroundStyle(Color.juneTextSecondary)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 52)

                        // Form
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Sign in to June")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.juneTextPrimary)
                                .padding(.bottom, 28)

                            VStack(spacing: 20) {
                                JuneTextField(
                                    label: "Username or Email",
                                    placeholder: "username or email",
                                    text: $loginInput,
                                    keyboardType: .emailAddress,
                                    autocapitalization: .never,
                                    submitLabel: .next
                                )

                                JuneTextField(
                                    label: "Password",
                                    placeholder: "password",
                                    text: $password,
                                    isSecure: true,
                                    submitLabel: .done,
                                    onSubmit: handleLogin
                                )
                            }
                            .padding(.bottom, 24)

                            JunePrimaryButton(title: "Sign In", isLoading: isLoading) {
                                handleLogin()
                            }
                            .padding(.bottom, 24)

                            // Divider
                            HStack {
                                Rectangle().frame(height: 0.5).foregroundStyle(Color.juneBorder)
                                Text("or")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.juneTextTertiary)
                                    .padding(.horizontal, 12)
                                Rectangle().frame(height: 0.5).foregroundStyle(Color.juneBorder)
                            }
                            .padding(.bottom, 24)

                            JuneOutlineButton(title: "Create an account") {
                                showSignup = true
                            }
                        }
                        .padding(.horizontal, 32)

                        Spacer().frame(height: 60)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
            .overlay(alignment: .top) {
                if let error = errorMessage {
                    ErrorBanner(message: error)
                        .padding(.top, 56)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: errorMessage != nil)
        }
    }

    private func handleLogin() {
        guard !loginInput.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            showError("Please enter your username/email and password")
            return
        }

        isLoading = true
        Task {
            do {
                try await auth.login(login: loginInput.trimmingCharacters(in: .whitespaces), password: password)
            } catch {
                showError(error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func showError(_ msg: String) {
        errorMessage = msg
        Task {
            try? await Task.sleep(for: .seconds(3))
            errorMessage = nil
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthManager.shared)
}
