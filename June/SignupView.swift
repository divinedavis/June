import SwiftUI

struct SignupView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var displayName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var usernameError: String?

    var body: some View {
        ZStack {
            Color.juneBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    FalconLogo(size: 52)
                        .padding(.top, 8)
                        .padding(.bottom, 28)

                    Text(step == 1 ? "Create your account" : "Complete sign up")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.juneTextPrimary)
                        .padding(.bottom, 20)

                    // Step indicator
                    StepIndicator(step: step, total: 2)
                        .padding(.bottom, 32)

                    // Fields
                    VStack(spacing: 20) {
                        if step == 1 {
                            JuneTextField(label: "Name", placeholder: "Your display name",
                                          text: $displayName)

                            VStack(alignment: .leading, spacing: 6) {
                                JuneTextField(
                                    label: "Username",
                                    placeholder: "your_username",
                                    text: $username,
                                    autocapitalization: .never,
                                    submitLabel: .done
                                )
                                .onChange(of: username) { _, new in
                                    validateUsername(new)
                                }

                                if let err = usernameError {
                                    Text(err)
                                        .font(.caption)
                                        .foregroundStyle(Color.juneError)
                                } else if !username.isEmpty {
                                    Text("@\(username.lowercased())")
                                        .font(.caption)
                                        .foregroundStyle(Color.juneTextSecondary)
                                }
                            }

                        } else {
                            JuneTextField(label: "Email", placeholder: "you@example.com",
                                          text: $email, keyboardType: .emailAddress,
                                          autocapitalization: .never)

                            JuneTextField(label: "Password", placeholder: "At least 8 characters",
                                          text: $password, isSecure: true)

                            JuneTextField(label: "Confirm Password", placeholder: "Repeat password",
                                          text: $confirmPassword, isSecure: true,
                                          submitLabel: .done, onSubmit: handleSignup)

                            Text("By signing up, you agree to our Terms of Service and Privacy Policy.")
                                .font(.caption)
                                .foregroundStyle(Color.juneTextTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 28)

                    // Action button
                    if step == 1 {
                        JunePrimaryButton(title: "Continue") { handleStep1() }
                    } else {
                        JunePrimaryButton(title: "Create Account", isLoading: isLoading) { handleSignup() }
                    }

                    // Sign in link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(Color.juneTextSecondary)
                        Button("Sign In") { dismiss() }
                            .foregroundStyle(Color.juneAccent)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
                .padding(.horizontal, 32)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if step > 1 { step = 1 } else { dismiss() }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(Color.juneTextPrimary)
                }
            }
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

    private func validateUsername(_ value: String) {
        if value.isEmpty { usernameError = nil; return }
        let valid = value.range(of: #"^[a-zA-Z0-9_]{3,30}$"#, options: .regularExpression) != nil
        usernameError = valid ? nil : "3–30 characters: letters, numbers, and _ only"
    }

    private func handleStep1() {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Please enter your name"); return
        }
        guard !username.isEmpty, usernameError == nil else {
            showError("Please enter a valid username"); return
        }
        withAnimation(.easeInOut) { step = 2 }
    }

    private func handleSignup() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError("Please enter your email"); return
        }
        guard password.count >= 8 else {
            showError("Password must be at least 8 characters"); return
        }
        guard password == confirmPassword else {
            showError("Passwords do not match"); return
        }

        isLoading = true
        Task {
            do {
                try await auth.signup(
                    username: username.lowercased(),
                    email: email.lowercased(),
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
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

struct StepIndicator: View {
    let step: Int
    let total: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...total, id: \.self) { i in
                Circle()
                    .fill(i <= step ? Color.juneAccent : Color.juneBorder)
                    .frame(width: 10, height: 10)
                if i < total {
                    Rectangle()
                        .fill(i < step ? Color.juneAccent : Color.juneBorder)
                        .frame(height: 2)
                        .padding(.horizontal, 6)
                }
            }
        }
        .frame(width: 80)
        .animation(.easeInOut, value: step)
    }
}
