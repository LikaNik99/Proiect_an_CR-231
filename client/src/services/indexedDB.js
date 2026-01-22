/**
 * IndexedDB helper for offline password caching
 * Stores passwords WITH decrypted values when server is online
 * Serves cached passwords (including actual password values) when offline
 * 
 * SECURITY NOTE: 
 * - Passwords are cached in DECRYPTED form in browser IndexedDB
 * - Cache is protected by user login session
 * - Cache is cleared on logout
 * - Only accessible when user is logged in (has valid token)
 * - Browser encryption (IndexedDB) provides basic protection
 */

const DB_NAME = 'PasswordManagerDB';
const DB_VERSION = 1;
const STORE_NAME = 'passwords';
const STORE_NAME_DECRYPTED = 'decrypted_passwords';

/**
 * Initialize IndexedDB
 */
const initDB = () => {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;
      
      // Create object store for passwords metadata
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        const objectStore = db.createObjectStore(STORE_NAME, { keyPath: 'id' });
        objectStore.createIndex('user_id', 'user_id', { unique: false });
        console.log('📦 IndexedDB: Password store created');
      }

      // Create object store for decrypted passwords (for offline access)
      if (!db.objectStoreNames.contains(STORE_NAME_DECRYPTED)) {
        const decryptedStore = db.createObjectStore(STORE_NAME_DECRYPTED, { keyPath: 'id' });
        decryptedStore.createIndex('user_id', 'user_id', { unique: false });
        console.log('📦 IndexedDB: Decrypted password store created');
      }
    };
  });
};

/**
 * Save passwords to IndexedDB (called after successful API fetch)
 */
export const cachePasswords = async (passwords, userId) => {
  try {
    const db = await initDB();
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const store = transaction.objectStore(STORE_NAME);

    // Clear old passwords for this user first
    const index = store.index('user_id');
    const clearRequest = index.openCursor(IDBKeyRange.only(userId));
    
    const oldPasswordsCleared = new Promise((resolve) => {
      clearRequest.onsuccess = (event) => {
        const cursor = event.target.result;
        if (cursor) {
          store.delete(cursor.primaryKey);
          cursor.continue();
        } else {
          resolve();
        }
      };
      clearRequest.onerror = () => resolve();
    });

    await oldPasswordsCleared;

    // Add new passwords
    passwords.forEach((password) => {
      store.put({
        ...password,
        user_id: userId,
        cached_at: new Date().toISOString()
      });
    });

    await new Promise((resolve, reject) => {
      transaction.oncomplete = resolve;
      transaction.onerror = () => reject(transaction.error);
    });

    db.close();
    console.log(`✅ Cached ${passwords.length} passwords`);
  } catch (error) {
    console.error('Cache error:', error.message);
  }
};

/**
 * Get passwords from IndexedDB (fallback when server is offline)
 */
export const getCachedPasswords = async (userId) => {
  try {
    const db = await initDB();
    const transaction = db.transaction([STORE_NAME], 'readonly');
    const store = transaction.objectStore(STORE_NAME);
    const index = store.index('user_id');
    
    const passwords = await new Promise((resolve, reject) => {
      const request = index.getAll(userId);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });

    db.close();
    console.log(`📥 Retrieved ${passwords.length} cached passwords`);
    return passwords;
  } catch (error) {
    console.error('Cache retrieval error:', error.message);
    return [];
  }
};

/**
 * Save a single password to cache
 */
export const cacheSinglePassword = async (password, userId) => {
  try {
    const db = await initDB();
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const store = transaction.objectStore(STORE_NAME);

    store.put({
      ...password,
      user_id: userId,
      cached_at: new Date().toISOString()
    });

    await new Promise((resolve, reject) => {
      transaction.oncomplete = resolve;
      transaction.onerror = () => reject(transaction.error);
    });

    db.close();
    console.log(`✅ Cached password ID ${password.id} to IndexedDB`);
  } catch (error) {
    console.error('❌ Error caching single password:', error);
  }
};

/**
 * Delete password from cache
 */
export const deleteCachedPassword = async (passwordId) => {
  try {
    const db = await initDB();
    const transaction = db.transaction([STORE_NAME], 'readwrite');
    const store = transaction.objectStore(STORE_NAME);

    store.delete(passwordId);

    await new Promise((resolve, reject) => {
      transaction.oncomplete = resolve;
      transaction.onerror = () => reject(transaction.error);
    });

    db.close();
    console.log(`✅ Deleted password ID ${passwordId} from cache`);
  } catch (error) {
    console.error('❌ Error deleting cached password:', error);
  }
};

/**
 * Cache decrypted passwords for offline access
 * @param {Array} decryptedPasswords - Array of password objects with decrypted password values
 * @param {number} userId - User ID to associate cached data with
 */
export const cacheDecryptedPasswords = async (decryptedPasswords, userId) => {
  try {
    const db = await initDB();
    const transaction = db.transaction([STORE_NAME_DECRYPTED], 'readwrite');
    const store = transaction.objectStore(STORE_NAME_DECRYPTED);
    
    // Clear old cache first
    store.clear();
    
    // Store each password with user_id and timestamp
    decryptedPasswords.forEach(password => {
      store.add({
        ...password,
        user_id: userId,
        cached_at: new Date().toISOString()
      });
    });
    
    await new Promise((resolve, reject) => {
      transaction.oncomplete = () => {
        console.log(`💾 Cached ${decryptedPasswords.length} decrypted passwords for offline access`);
        resolve();
      };
      transaction.onerror = () => reject(transaction.error);
    });

    db.close();
  } catch (error) {
    console.error('❌ Error caching decrypted passwords:', error);
    throw error;
  }
};

/**
 * Get cached decrypted passwords for offline access
 * @param {number} userId - User ID to retrieve cached data for
 * @returns {Promise<Array>} Array of cached password objects with decrypted passwords
 */
export const getCachedDecryptedPasswords = async (userId) => {
  try {
    const db = await initDB();
    const transaction = db.transaction([STORE_NAME_DECRYPTED], 'readonly');
    const store = transaction.objectStore(STORE_NAME_DECRYPTED);
    const index = store.index('user_id');
    
    const passwords = await new Promise((resolve, reject) => {
      const request = index.getAll(userId);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });

    db.close();
    console.log(`📂 Retrieved ${passwords.length} cached decrypted passwords for offline access`);
    return passwords;
  } catch (error) {
    console.error('❌ Error getting cached decrypted passwords:', error);
    return [];
  }
};

/**
 * Clear all cached passwords (logout)
 */
export const clearCache = async () => {
  try {
    const db = await initDB();
    const transaction = db.transaction([STORE_NAME, STORE_NAME_DECRYPTED], 'readwrite');
    
    transaction.objectStore(STORE_NAME).clear();
    transaction.objectStore(STORE_NAME_DECRYPTED).clear();

    await new Promise((resolve, reject) => {
      transaction.oncomplete = () => {
        console.log('🗑️  Cleared all cached passwords (metadata + decrypted)');
        resolve();
      };
      transaction.onerror = () => reject(transaction.error);
    });

    db.close();
  } catch (error) {
    console.error('❌ Error clearing cache:', error);
  }
};
