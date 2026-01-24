const TOKEN_KEY = "token";
const ROLE_KEY = "role";
const ADMIN_RESTAURANTS_KEY = "adminRestaurantIds";

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string, role: string, adminRestaurantIds: number[]) {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(ROLE_KEY, role);
  localStorage.setItem(ADMIN_RESTAURANTS_KEY, JSON.stringify(adminRestaurantIds));
}

export function clearToken() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(ROLE_KEY);
  localStorage.removeItem(ADMIN_RESTAURANTS_KEY);
}

export function getRole(): string | null {
  return localStorage.getItem(ROLE_KEY);
}

export function getAdminRestaurantIds(): number[] {
  const data = localStorage.getItem(ADMIN_RESTAURANTS_KEY);
  return data ? JSON.parse(data) : [];
}
