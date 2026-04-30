import SwiftUI

enum EmailAuthMode: Hashable {
    case signIn
    case signUp
}

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mode: EmailAuthMode = .signIn
    @State private var showingComingSoon = false

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 0) {
                cancelBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 24)
                        brandIcon
                        Spacer().frame(height: 24)
                        headline
                            .padding(.horizontal, 32)
                        Spacer().frame(height: 36)
                        fields
                            .padding(.horizontal, 24)
                        Spacer().frame(height: 18)
                        if mode == .signUp {
                            disclaimer
                                .padding(.horizontal, 36)
                                .transition(.opacity)
                        }
                        Spacer().frame(height: 24)
                        submitButton
                            .padding(.horizontal, 24)
                        Spacer().frame(height: 16)
                        toggleLink
                            .padding(.bottom, 32)
                    }
                }
            }
        }
        .preferredColorScheme(.light)
        .alert("Coming soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Email sign-in is on the way. For now, use Continue with Apple from the previous screen.")
        }
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.40, green: 0.56, blue: 1.0),
                    Color(red: 0.78, green: 0.86, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ConcentricRings()
                .ignoresSafeArea()
        }
    }

    private var cancelBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white.opacity(0.18)))
            }
            Spacer()
        }
    }

    // MARK: - Brand icon + headline

    private var brandIcon: some View {
        Image(systemName: "location.viewfinder")
            .font(.system(size: 26, weight: .semibold))
            .foregroundStyle(Color(red: 0.36, green: 0.50, blue: 0.96))
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.96))
            )
            .shadow(color: .black.opacity(0.10), radius: 10, y: 4)
    }

    private var headline: some View {
        Group {
            if mode == .signIn {
                VStack(spacing: 4) {
                    Text("Welcome back to")
                        .font(.system(size: 28, weight: .bold))
                    Text("your June")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .italic()
                }
            } else {
                VStack(spacing: 4) {
                    Text("Where all your")
                        .font(.system(size: 28, weight: .bold))
                    Text("Places begin")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .italic()
                }
            }
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        .id(mode)
        .transition(.opacity)
    }

    // MARK: - Fields

    private var fields: some View {
        VStack(spacing: 14) {
            if mode == .signUp {
                GlassField(
                    placeholder: "Full name",
                    text: $fullName,
                    isSecure: false,
                    contentType: .name,
                    keyboard: .default,
                    autocapitalize: .words,
                    autocorrect: false
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            GlassField(
                placeholder: "Email",
                text: $email,
                isSecure: false,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                autocapitalize: .never,
                autocorrect: false
            )
            GlassField(
                placeholder: "Password",
                text: $password,
                isSecure: true,
                contentType: mode == .signIn ? .password : .newPassword,
                keyboard: .default,
                autocapitalize: .never,
                autocorrect: false
            )
        }
    }

    // MARK: - Disclaimer + button + toggle

    private var disclaimer: some View {
        let footer = (Text("By creating an account, you agree to our ")
            + Text("Terms of Service").underline()
            + Text(" and ")
            + Text("Privacy Policy").underline()
            + Text(". We won't sell your personal information."))
        return footer
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.92))
            .multilineTextAlignment(.center)
    }

    private var submitButton: some View {
        Button {
            showingComingSoon = true
        } label: {
            Group {
                if mode == .signIn {
                    Text("Sign in")
                } else {
                    Text("Create account")
                }
            }
            .id(mode)
            .transition(.opacity)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isValid ? Color(red: 0.36, green: 0.50, blue: 0.96) : Color(white: 0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule().fill(Color.white.opacity(isValid ? 1.0 : 0.65))
            )
            .shadow(color: .black.opacity(0.10), radius: 10, y: 4)
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
            .id("lead-\(mode)")
            .transition(.opacity)
            .font(.system(size: 14))
            .foregroundStyle(.white.opacity(0.85))

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
                .id("action-\(mode)")
                .transition(.opacity)
                .font(.system(size: 14, weight: .semibold))
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
            return !fullName.trimmingCharacters(in: .whitespaces).isEmpty
                && email.contains("@")
                && password.count >= 6
        }
    }
}

// MARK: - GlassField

private struct GlassField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let contentType: UITextContentType?
    let keyboard: UIKeyboardType
    let autocapitalize: TextInputAutocapitalization
    let autocorrect: Bool

    var body: some View {
        Group {
            if isSecure {
                SecureField("", text: $text, prompt: prompt)
            } else {
                TextField("", text: $text, prompt: prompt)
                    .keyboardType(keyboard)
                    .textInputAutocapitalization(autocapitalize)
                    .autocorrectionDisabled(!autocorrect)
            }
        }
        .textContentType(contentType)
        .foregroundStyle(.white)
        .font(.system(size: 16))
        .padding(.horizontal, 22)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.4), lineWidth: 1)
        )
    }

    private var prompt: Text {
        Text(placeholder).foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Concentric rings background pattern

private struct ConcentricRings: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let cx = size.width / 2
                let cy = size.height * 0.42
                let baseRadius = size.width * 0.24
                for i in 0..<10 {
                    let radius = baseRadius + CGFloat(i) * size.width * 0.085
                    let rect = CGRect(
                        x: cx - radius,
                        y: cy - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    let alpha: Double = max(0.08, 0.30 - Double(i) * 0.022)
                    ctx.stroke(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(alpha)),
                        lineWidth: 1
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
