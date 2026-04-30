import AuthenticationServices
import Foundation
import Security

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var userIdentifier: String?
    @Published private(set) var displayName: String?
    @Published var errorMessage: String?

    private let keychainService = "com.divinedavis.june.auth"
    private let keychainAccount = "appleUserIdentifier"

    override init() {
        super.init()
        if let stored = readKeychain() {
            self.userIdentifier = stored
            self.isSignedIn = true
            verifyAppleCredential(for: stored)
        }
    }

    func handle(authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Unsupported credential type."
            return
        }
        let identifier = credential.user
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        writeKeychain(value: identifier)
        userIdentifier = identifier
        displayName = name.isEmpty ? nil : name
        isSignedIn = true
    }

    func signOut() {
        deleteKeychain()
        userIdentifier = nil
        displayName = nil
        isSignedIn = false
    }

    private func verifyAppleCredential(for identifier: String) {
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: identifier) { [weak self] state, _ in
            guard let self else { return }
            if state != .authorized {
                Task { @MainActor in self.signOut() }
            }
        }
    }

    private func writeKeychain(value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    private func readKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }
}
