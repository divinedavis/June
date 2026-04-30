import AuthenticationServices
import Foundation
import Security
import UIKit

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var userIdentifier: String?
    @Published private(set) var displayName: String?
    @Published var errorMessage: String?

    private let keychainService = "com.divinedavis.june.auth"
    private let keychainAccount = "appleUserIdentifier"
    private var appleSignInCoordinator: AppleSignInCoordinator?

    override init() {
        super.init()
        if let stored = readKeychain() {
            self.userIdentifier = stored
            self.isSignedIn = true
            verifyAppleCredential(for: stored)
        }
    }

    /// Trigger Sign in with Apple directly via ASAuthorizationController. Bypasses
    /// SignInWithAppleButton's internal click→sheet pipeline so the system sheet
    /// comes up immediately on tap.
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let coordinator = AppleSignInCoordinator(
            onSuccess: { [weak self] authorization in
                Task { @MainActor in
                    self?.handle(authorization: authorization)
                    self?.appleSignInCoordinator = nil
                }
            },
            onFailure: { [weak self] error in
                Task { @MainActor in
                    if (error as? ASAuthorizationError)?.code != .canceled {
                        self?.errorMessage = error.localizedDescription
                    }
                    self?.appleSignInCoordinator = nil
                }
            }
        )
        appleSignInCoordinator = coordinator

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = coordinator
        controller.presentationContextProvider = coordinator
        controller.performRequests()
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

private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let onSuccess: (ASAuthorization) -> Void
    private let onFailure: (Error) -> Void

    init(onSuccess: @escaping (ASAuthorization) -> Void,
         onFailure: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        onSuccess(authorization)
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        onFailure(error)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }
            .first
            ?? UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.windows.first }
                .first
            ?? ASPresentationAnchor()
    }
}
