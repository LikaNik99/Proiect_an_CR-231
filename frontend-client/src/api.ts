import axios from "axios";

export const api = axios.create({
  baseURL: "", // folosim proxy Vite, deci rutele sunt /auth, /me, etc.
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    console.error("API Error:", err);
    return Promise.reject(err);
  }
);
