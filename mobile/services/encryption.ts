import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64, encodeUTF8, decodeUTF8 } from 'tweetnacl-util';
import * as SecureStore from 'expo-secure-store';

const PRIVATE_KEY_STORAGE = 'june_private_key';
const PUBLIC_KEY_STORAGE = 'june_public_key';

/**
 * Generate or retrieve existing keypair for this device
 */
export const getOrCreateKeyPair = async (): Promise<{ publicKey: string; privateKey: string }> => {
  const storedPrivate = await SecureStore.getItemAsync(PRIVATE_KEY_STORAGE);
  const storedPublic = await SecureStore.getItemAsync(PUBLIC_KEY_STORAGE);

  if (storedPrivate && storedPublic) {
    return { publicKey: storedPublic, privateKey: storedPrivate };
  }

  const keyPair = nacl.box.keyPair();
  const publicKey = encodeBase64(keyPair.publicKey);
  const privateKey = encodeBase64(keyPair.secretKey);

  await SecureStore.setItemAsync(PRIVATE_KEY_STORAGE, privateKey);
  await SecureStore.setItemAsync(PUBLIC_KEY_STORAGE, publicKey);

  return { publicKey, privateKey };
};

/**
 * Encrypt a message to send to a recipient
 * Uses NaCl box (Curve25519 + XSalsa20 + Poly1305)
 */
export const encryptMessage = (
  message: string,
  recipientPublicKeyBase64: string,
  senderPrivateKeyBase64: string
): { encrypted: string; nonce: string } => {
  const nonce = nacl.randomBytes(nacl.box.nonceLength);
  const messageUint8 = encodeUTF8(message);
  const recipientPublicKey = decodeBase64(recipientPublicKeyBase64);
  const senderPrivateKey = decodeBase64(senderPrivateKeyBase64);

  const encrypted = nacl.box(messageUint8, nonce, recipientPublicKey, senderPrivateKey);

  return {
    encrypted: encodeBase64(encrypted),
    nonce: encodeBase64(nonce),
  };
};

/**
 * Decrypt a message received from a sender
 */
export const decryptMessage = (
  encryptedBase64: string,
  nonceBase64: string,
  senderPublicKeyBase64: string,
  recipientPrivateKeyBase64: string
): string | null => {
  try {
    const encrypted = decodeBase64(encryptedBase64);
    const nonce = decodeBase64(nonceBase64);
    const senderPublicKey = decodeBase64(senderPublicKeyBase64);
    const recipientPrivateKey = decodeBase64(recipientPrivateKeyBase64);

    const decrypted = nacl.box.open(encrypted, nonce, senderPublicKey, recipientPrivateKey);

    if (!decrypted) return null;
    return decodeUTF8(decrypted);
  } catch {
    return null;
  }
};

export const getMyPrivateKey = async (): Promise<string | null> => {
  return SecureStore.getItemAsync(PRIVATE_KEY_STORAGE);
};

export const getMyPublicKey = async (): Promise<string | null> => {
  return SecureStore.getItemAsync(PUBLIC_KEY_STORAGE);
};
