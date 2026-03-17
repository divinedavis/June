import SwiftUI

@Observable
final class AuthManager {
    static let shared = AuthManager()
    private init() {
        loadStoredUser()
    }

    var user: JuneUser?
    var isAuthenticated: Bool { user != nil }
    var isLoading = true

    private func loadStoredUser() {
        guard KeychainHelper.read(for: KeychainHelper.tokenKey) != nil else {
            isLoading = false
            return
        }
        Task {
            do {
                user = try await APIService.shared.me()
            } catch {
                KeychainHelper.delete(for: KeychainHelper.tokenKey)
            }
            isLoading = false
        }
    }

    func login(login: String, password: String) async throws {
        let response = try await APIService.shared.login(login: login, password: password)
        KeychainHelper.save(response.token, for: KeychainHelper.tokenKey)
        user = response.user
        await initializeEncryption()
    }

    func signup(username: String, email: String, password: String, displayName: String) async throws {
        let response = try await APIService.shared.signup(
            username: username, email: email, password: password, displayName: displayName
        )
        KeychainHelper.save(response.token, for: KeychainHelper.tokenKey)
        user = response.user
        await initializeEncryption()
    }

    func logout() {
        KeychainHelper.delete(for: KeychainHelper.tokenKey)
        user = nil
    }

    func refreshUser() async {
        guard let updated = try? await APIService.shared.me() else { return }
        user = updated
    }

    func updateUser(_ updated: JuneUser) {
        user = updated
    }

    private func initializeEncryption() async {
        guard let (publicKey, _) = try? EncryptionService.getOrCreateKeyPair() else { return }
        try? await APIService.shared.uploadPublicKey(publicKey)
    }
}
