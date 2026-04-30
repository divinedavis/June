import SwiftUI

enum EmailAuthMode: Hashable {
    case signIn
    case signUp
}

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode: EmailAuthMode = .signIn
    @State private var showingComingSoon = false

    // Sign in
    @State private var signInEmail = ""
    @State private var signInPassword = ""

    // Sign up
    @State private var username = ""
    @State private var signUpEmail = ""
    @State private var signUpPassword = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)

            ScrollView {
                ZStack(alignment: .top) {
                    if mode == .signIn {
                        signInContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    if mode == .signUp {
                        signUpContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(JuneTheme.sheetBackground.ignoresSafeArea())
        .alert("Coming soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Email sign-in is on the way. For now, use Continue with Apple from the previous screen.")
        }
    }

    // MARK: - Sign In

    private var signInContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(caption: "Welcome back.", title: "Sign in to June.")

            subtitle
                .padding(.bottom, 32)

            field(label: "Email", text: $signInEmail, isSecure: false, contentType: .emailAddress, keyboard: .emailAddress)
                .padding(.bottom, 24)

            field(label: "Password", text: $signInPassword, isSecure: true, contentType: .password)
                .padding(.bottom, 32)

            submitButton(title: "Sign In", enabled: signInValid) { showingComingSoon = true }

            toggleLink(prompt: "Don't have an account?", action: "Sign up") {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { mode = .signUp }
            }
            .padding(.top, 16)
        }
    }

    private var signInValid: Bool {
        signInEmail.contains("@") && signInPassword.count >= 1
    }

    // MARK: - Sign Up

    private var signUpContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading(caption: "Let's get started.", title: "Join June.")

            subtitle
                .padding(.bottom, 32)

            field(label: "Username", text: $username, isSecure: false, contentType: .username, autocapitalize: .never, autocorrect: false)
                .padding(.bottom, 20)
            field(label: "Email", text: $signUpEmail, isSecure: false, contentType: .emailAddress, keyboard: .emailAddress, autocapitalize: .never, autocorrect: false)
                .padding(.bottom, 20)
            field(label: "Password", text: $signUpPassword, isSecure: true, contentType: .newPassword)
                .padding(.bottom, 20)
            field(label: "Confirm password", text: $confirmPassword, isSecure: true, contentType: .newPassword)
                .padding(.bottom, 32)

            submitButton(title: "Create Account", enabled: signUpValid) { showingComingSoon = true }

            toggleLink(prompt: "Already have an account?", action: "Sign in") {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { mode = .signIn }
            }
            .padding(.top, 16)
        }
    }

    private var signUpValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
            && signUpEmail.contains("@")
            && signUpPassword.count >= 6
            && signUpPassword == confirmPassword
    }

    // MARK: - Building blocks

    private func heading(caption: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(caption)
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 38, weight: .heavy))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var subtitle: some View {
        Text("All your favorite places, in one place.")
            .font(.system(size: 17))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func field(
        label: String,
        text: Binding<String>,
        isSecure: Bool,
        contentType: UITextContentType? = nil,
        keyboard: UIKeyboardType = .default,
        autocapitalize: TextInputAutocapitalization = .sentences,
        autocorrect: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(autocapitalize)
                        .autocorrectionDisabled(!autocorrect)
                }
            }
            .textContentType(contentType)
            .foregroundStyle(.white)
            .font(.system(size: 17))
            .padding(.vertical, 6)
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
        }
    }

    private func submitButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule().fill(enabled ? JuneTheme.accent : Color.white.opacity(0.18))
                )
        }
        .disabled(!enabled)
    }

    private func toggleLink(prompt: String, action: String, perform: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Spacer()
            Text("\(prompt) ")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            Button(action: perform) {
                Text(action)
                    .font(.system(size: 15, weight: .semibold))
                    .underline()
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}
