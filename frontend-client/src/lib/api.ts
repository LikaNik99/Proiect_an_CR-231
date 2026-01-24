import { getToken } from "./auth";

export function normalizeRomanianChars(text: string): string {
  return text.replace(/[ȘŞş]/g, (c) => (c === "Ș" || c === "Ş" ? "S" : "s"));
}

export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = getToken();

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(init.headers as any),
  };

  if (token) headers["Authorization"] = `Bearer ${token}`;

  const res = await fetch(path, { ...init, headers });

  if (!res.ok) {
    const contentType = res.headers.get("content-type");
    let message = `${res.status} ${res.statusText}`;
    if (contentType && contentType.includes("application/json")) {
      try {
        const json = await res.json();
        message = json.message || message;
      } catch {
        // ignore
      }
    } else {
      const text = await res.text().catch(() => "");
      if (text) message = text;
    }
    throw new Error(message);
  }

  // availability poate întoarce listă simplă JSON -> e ok
  return (await res.json()) as T;
}
