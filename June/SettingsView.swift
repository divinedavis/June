import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var bio = ""
    @State private var isPublic = true
    @State private var isSaving = false
    @State private var savedBanner = false
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color.juneBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Account section
                    settingsSection("Account") {
                        settingsRow(icon: "person.fill", label: "Username") {
                            Text("@\(auth.user?.username ?? "")")
                                .foregroundStyle(Color.juneTextSecondary)
                        }
                        Divider().background(Color.juneBorder).padding(.leading, 48)
                        settingsRow(icon: "envelope.fill", label: "Email") {
                            Text(auth.user?.email ?? "")
                                .foregroundStyle(Color.juneTextSecondary)
                                .lineLimit(1)
                        }
                    }

                    // Profile section
                    settingsSection("Edit Profile") {
                        VStack(alignment: .leading, spacing: 16) {
                            JuneTextField(label: "Display Name", placeholder: "Your name",
                                          text: $displayName)
                            JuneTextField(label: "Bio", placeholder: "Tell people about yourself",
                                          text: $bio)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)

                        JunePrimaryButton(title: "Save Changes", isLoading: isSaving) {
                            saveProfile()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }

                    // Privacy section
                    settingsSection("Privacy") {
                        HStack(spacing: 14) {
                            Image(systemName: "globe")
                                .frame(width: 22)
                                .foregroundStyle(Color.juneTextSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Public Account")
                                    .foregroundStyle(Color.juneTextPrimary)
                                Text(isPublic ? "Anyone can see your posts" : "Only followers can see your posts")
                                    .font(.caption)
                                    .foregroundStyle(Color.juneTextSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $isPublic)
                                .tint(Color.juneAccent)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    // About section
                    settingsSection("About") {
                        settingsRow(icon: "info.circle.fill", label: "Version") {
                            Text("1.0.0")
                                .foregroundStyle(Color.juneTextSecondary)
                        }
                        Divider().background(Color.juneBorder).padding(.leading, 48)
                        settingsRow(icon: "shield.fill", label: "Privacy Policy", chevron: true) { EmptyView() }
                        Divider().background(Color.juneBorder).padding(.leading, 48)
                        settingsRow(icon: "doc.text.fill", label: "Terms of Service", chevron: true) { EmptyView() }
                    }

                    // Sign out
                    Button {
                        showLogoutAlert = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(Color.juneError)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.juneError.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: JuneRadius.card))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = auth.user?.displayName ?? ""
            bio         = auth.user?.bio ?? ""
            isPublic    = auth.user?.isPublic ?? true
        }
        .overlay(alignment: .top) {
            if savedBanner {
                Text("Profile saved")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.juneRepost)
                    .clipShape(Capsule())
                    .padding(.top, 56)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: savedBanner)
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Sign Out", role: .destructive) {
                auth.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to use June.")
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.juneTextSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.juneSurface)
            .clipShape(RoundedRectangle(cornerRadius: JuneRadius.card))
            .overlay(RoundedRectangle(cornerRadius: JuneRadius.card).stroke(Color.juneBorder, lineWidth: 0.5))
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func settingsRow<T: View>(
        icon: String,
        label: String,
        chevron: Bool = false,
        @ViewBuilder trailing: () -> T
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(Color.juneTextSecondary)
            Text(label)
                .foregroundStyle(Color.juneTextPrimary)
            Spacer()
            trailing()
            if chevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.juneTextTertiary)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func saveProfile() {
        isSaving = true
        Task {
            if let updated = try? await APIService.shared.updateProfile(
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                bio: bio.trimmingCharacters(in: .whitespaces),
                isPublic: isPublic
            ) {
                auth.updateUser(updated)
                savedBanner = true
                try? await Task.sleep(for: .seconds(2))
                savedBanner = false
            }
            isSaving = false
        }
    }
}
