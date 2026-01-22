import axios from 'axios';
import { 
  cachePasswords, 
  getCachedPasswords, 
  cacheSinglePassword, 
  deleteCachedPassword,
  cacheDecryptedPasswords,
  getCachedDecryptedPasswords
} from './indexedDB';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api';

// Create axios instance
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Add token to requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Handle response errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Unauthorized - clear token and redirect to login
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth APIs
export const authAPI = {
  register: (username, email, password) => 
    api.post('/auth/register', { username, email, password }),
  
  login: (username, password) => 
    api.post('/auth/login', { username, password }),
  
  getMe: () => 
    api.get('/auth/me'),
  
  verifyPassword: (password) =>
    api.post('/auth/verify-password', { password }),
  
  updateProfile: (data) =>
    api.put('/auth/profile', data)
};

// Password APIs with offline support
export const passwordAPI = {
  getAll: async () => {
    try {
      const response = await api.get('/passwords');
      
      // Cache passwords metadata on successful fetch
      const user = JSON.parse(localStorage.getItem('user'));
      if (user && response.data.passwords) {
        await cachePasswords(response.data.passwords, user.id).catch(err => {
          console.warn('Failed to cache passwords:', err);
        });

        // Fetch decrypted passwords in background (don't block UI)
        console.log('🔐 Starting background fetch of decrypted passwords for offline cache...');
        Promise.all(
          response.data.passwords.map(async (pwd) => {
            try {
              const decryptedResponse = await api.get(`/passwords/${pwd.id}`);
              return {
                ...pwd,
                password: decryptedResponse.data.password.decrypted_password
              };
            } catch (err) {
              console.warn(`Failed to fetch password ${pwd.id}:`, err.message);
              return { ...pwd, password: null }; // Mark as failed
            }
          })
        ).then(async (decryptedPasswords) => {
          await cacheDecryptedPasswords(decryptedPasswords, user.id);
          console.log('✅ Background cache complete');
        }).catch(err => {
          console.warn('Failed to cache decrypted passwords:', err);
        });
      }
      
      return response;
    } catch (error) {
      // If server is offline, try to get cached passwords
      if (error.code === 'ERR_NETWORK' || error.message.includes('Network Error')) {
        console.log('📡 Server offline - loading from cache');
        const user = JSON.parse(localStorage.getItem('user'));
        if (user) {
          const cachedPasswords = await getCachedDecryptedPasswords(user.id);
          return {
            data: {
              passwords: cachedPasswords,
              fromCache: true,
              message: 'Loaded from offline cache'
            }
          };
        }
      }
      throw error;
    }
  },
  
  getOne: async (id) => {
    try {
      return await api.get(`/passwords/${id}`);
    } catch (error) {
      // If server is offline, try to get from decrypted cache
      if (error.code === 'ERR_NETWORK' || error.message.includes('Network Error')) {
        console.log('📡 Server offline - loading password from cache');
        const user = JSON.parse(localStorage.getItem('user'));
        if (user) {
          const cachedPasswords = await getCachedDecryptedPasswords(user.id);
          const password = cachedPasswords.find(p => p.id === parseInt(id));
          if (password) {
            return {
              data: {
                password: password.password,
                fromCache: true
              }
            };
          }
        }
      }
      throw error;
    }
  },
  
  create: async (data) => {
    try {
      const response = await api.post('/passwords', data);
      
      // Cache the new password
      const user = JSON.parse(localStorage.getItem('user'));
      if (user && response.data.password) {
        await cacheSinglePassword(response.data.password, user.id);
      }
      
      return response;
    } catch (error) {
      if (error.code === 'ERR_NETWORK' || error.message.includes('Network Error')) {
        throw new Error('Cannot create password while offline. Please reconnect to server.');
      }
      throw error;
    }
  },
  
  update: async (id, data) => {
    try {
      const response = await api.put(`/passwords/${id}`, data);
      
      // Update cache
      const user = JSON.parse(localStorage.getItem('user'));
      if (user) {
        // Re-fetch all to update cache
        const allPasswords = await getCachedPasswords(user.id);
        const updatedPasswords = allPasswords.map(p => 
          p.id === id ? { ...p, ...data } : p
        );
        await cachePasswords(updatedPasswords, user.id);
      }
      
      return response;
    } catch (error) {
      if (error.code === 'ERR_NETWORK' || error.message.includes('Network Error')) {
        throw new Error('Cannot update password while offline. Please reconnect to server.');
      }
      throw error;
    }
  },
  
  delete: async (id) => {
    try {
      const response = await api.delete(`/passwords/${id}`);
      
      // Remove from cache
      await deleteCachedPassword(id);
      
      return response;
    } catch (error) {
      if (error.code === 'ERR_NETWORK' || error.message.includes('Network Error')) {
        throw new Error('Cannot delete password while offline. Please reconnect to server.');
      }
      throw error;
    }
  },
  
  generate: (length) => 
    api.post('/passwords/generate', { length })
};

export default api;
