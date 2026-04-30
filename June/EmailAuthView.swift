import SwiftUI

enum EmailAuthMode: Hashable {
    case signIn
    case signUp
}

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mode: EmailAuthMode = .signIn
    @State private var showingComingSoon = false

    // Shared between sign-in and sign-up so values persist across the toggle.
    @State private var email = ""
    @State private var password = ""
    // Sign-up only.
    @State private var username = ""
    @State private var confirm = ""

    var body: some View {
        VStack(spacing: 0) {
            cancelBar
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    subtitle
                        .padding(.bottom, 32)
                    fields
                    submitButton
                    toggleLink
                        .padding(.top, 16)
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

    // MARK: - Bars

    private var cancelBar: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 17))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Header (caption + title) — crossfades on mode change

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if mode == .signIn {
                    Text("Welcome back.")
                } else {
                    Text("Let's get started.")
                }
            }
            .font(.system(size: 17))
            .foregroundStyle(.secondary)
            .id(mode.captionId)
            .transition(.opacity)

            Group {
                if mode == .signIn {
                    Text("Sign in to June.")
                } else {
                    Text("Join June.")
                }
            }
            .font(.system(size: 38, weight: .heavy))
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .id(mode.titleId)
            .transition(.opacity)
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

    // MARK: - Fields — Email + Password are persistent; Username slides in
    // from above, Confirm password slides in from below.

    private var fields: some View {
        VStack(alignment: .leading, spacing: 20) {
            if mode == .signUp {
                field(
                    label: "Username",
                    text: $username,
                    isSecure: false,
                    contentType: .username,
                    autocapitalize: .never,
                    autocorrect: false
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }

            field(
                label: "Email",
                text: $email,
                isSecure: false,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                autocapitalize: .never,
                autocorrect: false
            )

            field(
                label: "Password",
                text: $password,
                isSecure: true,
                contentType: mode == .signIn ? .password : .newPassword
            )

            if mode == .signUp {
                field(
                    label: "Confirm password",
                    text: $confirm,
                    isSecure: true,
                    contentType: .newPassword
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Submit + toggle

    private var submitButton: some View {
        Button {
            showingComingSoon = true
        } label: {
            Group {
                if mode == .signIn {
                    Text("Sign In")
                } else {
                    Text("Create Account")
                }
            }
            .id(mode.buttonId)
            .transition(.opacity)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule().fill(isValid ? JuneTheme.accent : Color.white.opacity(0.18))
            )
        }
        .disabled(!isValid)
    }

    private var toggleLink: some View {
        HStack(spacing: 0) {
            Spacer()
            Group {
                if mode == .signIn {
                    Text("Don't have an account? ")
                } else {
                    Text("Already have an account? ")
                }
            }
            .id(mode.toggleLeadId)
            .transition(.opacity)
            .font(.system(size: 15))
            .foregroundStyle(.secondary)

            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.84)) {
                    mode = (mode == .signIn) ? .signUp : .signIn
                }
            } label: {
                Group {
                    if mode == .signIn {
                        Text("Sign up")
                    } else {
                        Text("Sign in")
                    }
                }
                .id(mode.toggleActionId)
                .transition(.opacity)
                .font(.system(size: 15, weight: .semibold))
                .underline()
                .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        switch mode {
        case .signIn:
            return email.contains("@") && !password.isEmpty
        case .signUp:
            return !username.trimmingCharacters(in: .whitespaces).isEmpty
                && email.contains("@")
                && password.count >= 6
                && password == confirm
        }
    }

    // MARK: - Field builder

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
}

private extension EmailAuthMode {
    var captionId: String { "caption-\(self)" }
    var titleId: String { "title-\(self)" }
    var buttonId: String { "btn-\(self)" }
    var toggleLeadId: String { "togL-\(self)" }
    var toggleActionId: String { "togA-\(self)" }
}
