import Foundation
import CryptoKit

// End-to-end encryption using Curve25519 ECDH + AES-GCM
// Each user has a Curve25519 keypair stored in Keychain.
// To send a DM: derive shared secret via ECDH, then AES-GCM encrypt.

enum EncryptionService {

    // MARK: - Key management

    static func getOrCreateKeyPair() throws -> (publicKeyBase64: String, privateKeyBase64: String) {
        if let existingPrivate = KeychainHelper.read(for: KeychainHelper.privateKeyKey),
           let existingPublic  = KeychainHelper.read(for: KeychainHelper.publicKeyKey) {
            return (existingPublic, existingPrivate)
        }

        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey  = privateKey.publicKey

        let privateB64 = privateKey.rawRepresentation.base64EncodedString()
        let publicB64  = publicKey.rawRepresentation.base64EncodedString()

        KeychainHelper.save(privateB64, for: KeychainHelper.privateKeyKey)
        KeychainHelper.save(publicB64,  for: KeychainHelper.publicKeyKey)

        return (publicB64, privateB64)
    }

    // MARK: - Encrypt

    static func encrypt(
        message: String,
        recipientPublicKeyBase64: String,
        senderPrivateKeyBase64: String
    ) throws -> (ciphertext: String, nonce: String) {
        guard
            let recipientKeyData = Data(base64Encoded: recipientPublicKeyBase64),
            let senderKeyData    = Data(base64Encoded: senderPrivateKeyBase64)
        else { throw EncryptionError.invalidKey }

        let recipientPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientKeyData)
        let senderPrivateKey   = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: senderKeyData)

        let sharedSecret = try senderPrivateKey.sharedSecretFromKeyAgreement(with: recipientPublicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "june-dm-salt".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )

        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(Data(message.utf8), using: symmetricKey, nonce: nonce)

        let combined = sealedBox.combined ?? (nonce.dataRepresentation + sealedBox.ciphertext + sealedBox.tag)
        let nonceData = nonce.dataRepresentation

        return (
            ciphertext: combined.base64EncodedString(),
            nonce: nonceData.base64EncodedString()
        )
    }

    // MARK: - Decrypt

    static func decrypt(
        ciphertextBase64: String,
        nonceBase64: String,
        senderPublicKeyBase64: String,
        recipientPrivateKeyBase64: String
    ) -> String? {
        guard
            let ciphertextData       = Data(base64Encoded: ciphertextBase64),
            let senderKeyData        = Data(base64Encoded: senderPublicKeyBase64),
            let recipientPrivKeyData = Data(base64Encoded: recipientPrivateKeyBase64)
        else { return nil }

        do {
            let senderPublicKey      = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: senderKeyData)
            let recipientPrivateKey  = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: recipientPrivKeyData)

            let sharedSecret = try recipientPrivateKey.sharedSecretFromKeyAgreement(with: senderPublicKey)
            let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: "june-dm-salt".data(using: .utf8)!,
                sharedInfo: Data(),
                outputByteCount: 32
            )

            let sealedBox   = try AES.GCM.SealedBox(combined: ciphertextData)
            let decrypted   = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decrypted, encoding: .utf8)
        } catch {
            return nil
        }
    }

    enum EncryptionError: Error {
        case invalidKey
    }
}

// Convenience extension
extension AES.GCM.Nonce {
    var dataRepresentation: Data { withUnsafeBytes { Data($0) } }
}
