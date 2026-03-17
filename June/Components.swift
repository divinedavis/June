import SwiftUI

// MARK: - JuneTextField

struct JuneTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil

    @State private var showPassword = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.juneTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            HStack {
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                            .autocorrectionDisabled()
                    }
                }
                .foregroundStyle(Color.juneTextPrimary)

                if isSecure {
                    Button {
                        showPassword.toggle()
                    } label: {
                        Text(showPassword ? "Hide" : "Show")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.juneAccent)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.juneSurface)
            .overlay(
                RoundedRectangle(cornerRadius: JuneRadius.input)
                    .stroke(Color.juneBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: JuneRadius.input))
            .submitLabel(submitLabel)
            .onSubmit { onSubmit?() }
        }
    }
}

// MARK: - JunePrimaryButton

struct JunePrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text(title)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.juneAccent)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
    }
}

// MARK: - JuneOutlineButton

struct JuneOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.juneTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay(
                    Capsule().stroke(Color.juneBorder, lineWidth: 1)
                )
        }
    }
}

// MARK: - UserAvatar

struct UserAvatar: View {
    let url: String?
    let initials: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        fallbackView
                    }
                }
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var fallbackView: some View {
        ZStack {
            Color.juneSurfaceElevated
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(Color.juneAccent)
        }
    }
}

// MARK: - Stat View

struct StatView: View {
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .fontWeight(.bold)
                .foregroundStyle(Color.juneTextPrimary)
            Text(label)
                .foregroundStyle(Color.juneTextSecondary)
        }
        .font(.subheadline)
    }
}

// MARK: - Formatted count

extension Int {
    var formatted: String {
        if self >= 1_000_000 { return String(format: "%.1fM", Double(self) / 1_000_000) }
        if self >= 1_000     { return String(format: "%.1fK", Double(self) / 1_000) }
        return self > 0 ? "\(self)" : ""
    }
}

// MARK: - Toast / Error banner helper

struct ErrorBanner: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.juneError)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
