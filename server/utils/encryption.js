const crypto = require('crypto');

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY || 'your_32_character_encryption_key_change_this';
const ALGORITHM = 'aes-256-cbc';

// Ensure key is 32 bytes
const key = Buffer.from(ENCRYPTION_KEY.padEnd(32, '0').slice(0, 32));

/**
 * Encrypt a password
 * @param {string} text - Plain text password to encrypt
 * @returns {object} - Object containing encrypted data and IV
 */
function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  
  return {
    encryptedData: encrypted,
    iv: iv.toString('hex')
  };
}

/**
 * Decrypt a password
 * @param {string} encryptedData - Encrypted password
 * @param {string} ivHex - Initialization vector in hex format
 * @returns {string} - Decrypted password
 */
function decrypt(encryptedData, ivHex) {
  const iv = Buffer.from(ivHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}

/**
 * Generate a random secure password
 * @param {number} length - Length of password
 * @returns {string} - Generated password
 */
function generatePassword(length = 16) {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?';
  let password = '';
  const randomBytes = crypto.randomBytes(length);
  
  for (let i = 0; i < length; i++) {
    password += charset[randomBytes[i] % charset.length];
  }
  
  return password;
}

module.exports = {
  encrypt,
  decrypt,
  generatePassword
};
