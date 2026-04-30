import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var auth: AuthManager

    @State private var country: Country = .unitedStates
    @State private var phoneNumber: String = ""
    @State private var showingCountryPicker = false
    @State private var comingSoonProvider: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            backdrop
            authCard
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerView(selection: $country)
                .presentationDetents([.medium, .large])
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

    // MARK: - Backdrop (misty mountain + "june" wordmark)

    private var backdrop: some View {
        ZStack(alignment: .top) {
            Image("AuthBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Soft top vignette so the wordmark reads against the sky.
            LinearGradient(
                colors: [Color.black.opacity(0.18), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 360)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 140)
                Text("june")
                    .font(.system(size: 92, weight: .heavy, design: .default))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Auth card (bottom sheet over the backdrop)

    private var authCard: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 8)

            Text("Log in or sign up")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.bottom, 14)

            Divider().background(Color.white.opacity(0.08))

            ScrollView {
                VStack(spacing: 20) {
                    phoneCard.padding(.top, 20)

                    Text("We'll call or text to confirm your number. Standard message and data rates apply.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    continueButton

                    orDivider.padding(.vertical, 4)

                    VStack(spacing: 12) {
                        providerButton(
                            label: "Continue with email",
                            systemImage: "envelope",
                            iconColor: .white
                        ) { comingSoonProvider = "email" }

                        appleButton

                        providerButton(
                            label: "Continue with Google",
                            systemImage: "g.circle.fill",
                            iconColor: .white
                        ) { comingSoonProvider = "Google" }

                        providerButton(
                            label: "Continue with Facebook",
                            systemImage: "f.circle.fill",
                            iconColor: Color(red: 0.10, green: 0.46, blue: 0.96)
                        ) { comingSoonProvider = "Facebook" }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.66)
        .frame(maxWidth: .infinity)
        .background(
            JuneTheme.sheetBackground
                .opacity(0.94)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedCorner(radius: 28, corners: [.topLeft, .topRight]))
        .shadow(color: .black.opacity(0.4), radius: 24, y: -2)
    }

    private var phoneCard: some View {
        VStack(spacing: 0) {
            Button { showingCountryPicker = true } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Country/Region")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(country.displayName)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider().background(Color.white.opacity(0.08))

            HStack(spacing: 8) {
                Text(country.dialCode)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                TextField("", text: $phoneNumber, prompt: Text("Phone number").foregroundColor(.secondary))
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .foregroundStyle(.white)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var continueButton: some View {
        Button {
            comingSoonProvider = "phone"
        } label: {
            Text("Continue")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(JuneTheme.accent)
                        .opacity(phoneNumber.count >= 7 ? 1 : 0.45)
                )
        }
        .disabled(phoneNumber.count < 7)
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
            Text("or")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func providerButton(label: String, systemImage: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(iconColor)
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
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
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

// MARK: - Country picker

struct Country: Identifiable, Hashable {
    let id: String
    let name: String
    let dialCode: String

    var displayName: String { "\(name) (\(dialCode))" }

    static let unitedStates = Country(id: "US", name: "United States", dialCode: "+1")

    static let all: [Country] = [
        unitedStates,
        Country(id: "CA", name: "Canada", dialCode: "+1"),
        Country(id: "MX", name: "Mexico", dialCode: "+52"),
        Country(id: "GB", name: "United Kingdom", dialCode: "+44"),
        Country(id: "FR", name: "France", dialCode: "+33"),
        Country(id: "DE", name: "Germany", dialCode: "+49"),
        Country(id: "IT", name: "Italy", dialCode: "+39"),
        Country(id: "ES", name: "Spain", dialCode: "+34"),
        Country(id: "PT", name: "Portugal", dialCode: "+351"),
        Country(id: "BR", name: "Brazil", dialCode: "+55"),
        Country(id: "AR", name: "Argentina", dialCode: "+54"),
        Country(id: "JP", name: "Japan", dialCode: "+81"),
        Country(id: "KR", name: "South Korea", dialCode: "+82"),
        Country(id: "CN", name: "China", dialCode: "+86"),
        Country(id: "IN", name: "India", dialCode: "+91"),
        Country(id: "AU", name: "Australia", dialCode: "+61"),
        Country(id: "NZ", name: "New Zealand", dialCode: "+64"),
        Country(id: "ZA", name: "South Africa", dialCode: "+27"),
        Country(id: "NG", name: "Nigeria", dialCode: "+234"),
        Country(id: "AE", name: "United Arab Emirates", dialCode: "+971")
    ]
}

private struct CountryPickerView: View {
    @Binding var selection: Country
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Country.all) { country in
                Button {
                    selection = country
                    dismiss()
                } label: {
                    HStack {
                        Text(country.name)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(country.dialCode)
                            .foregroundStyle(.secondary)
                        if country.id == selection.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(JuneTheme.accent)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(JuneTheme.sheetBackground)
            .navigationTitle("Country/Region")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
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

private struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
