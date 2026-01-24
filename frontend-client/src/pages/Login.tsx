import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import { setToken } from "../lib/auth";
import type { LoginResponse } from "../types";

export default function Login() {
  const nav = useNavigate();
  const [isRegister, setIsRegister] = useState(false);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    setLoading(true);
    try {
      const endpoint = isRegister ? "/auth/register" : "/auth/login";
      const body = isRegister
        ? { fullName, email, password }
        : { email, password };

      const res = await api<LoginResponse>(endpoint, {
        method: "POST",
        body: JSON.stringify(body),
      });
      setToken(res.token, res.role, res.adminRestaurantIds);
      
      if (res.role === "ADMIN" || res.role === "SUPER_ADMIN") {
        nav("/admin");
      } else {
        nav("/restaurants");
      }
    } catch (e: any) {
      setErr(e.message ?? (isRegister ? "Înregistrare eșuată" : "Login eșuat"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div style={{ minHeight: "100vh", backgroundColor: "#f8fafc", display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
      <div style={{ backgroundColor: "white", borderRadius: 16, padding: 32, width: "100%", maxWidth: 420, boxShadow: "0 4px 20px rgba(0,0,0,0.1)" }}>
        <h2 style={{ margin: "0 0 24px 0", textAlign: "center", fontSize: 24, fontWeight: 700, color: "#1e293b" }}>
          {isRegister ? "Înregistrare" : "Login"}
        </h2>
        <form onSubmit={onSubmit} style={{ display: "grid", gap: 16 }}>
          {isRegister && (
            <div>
              <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase" }}>
                Nume complet
              </label>
              <input
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                style={{ width: "100%", padding: "12px 16px", borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 14, boxSizing: "border-box" }}
              />
            </div>
          )}
          <div>
            <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase" }}>
              Email
            </label>
            <input
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              type="email"
              style={{ width: "100%", padding: "12px 16px", borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 14, boxSizing: "border-box" }}
            />
          </div>
          <div>
            <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase" }}>
              Parolă
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={{ width: "100%", padding: "12px 16px", borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 14, boxSizing: "border-box" }}
            />
          </div>

          {err && (
            <div style={{ color: "#dc2626", fontSize: 14, padding: "12px 16px", backgroundColor: "#fef2f2", borderRadius: 8 }}>
              {err}
            </div>
          )}

          <button
            disabled={loading}
            type="submit"
            style={{
              padding: "12px 24px",
              fontSize: 16,
              fontWeight: 600,
              borderRadius: 8,
              border: "none",
              backgroundColor: "#6366f1",
              color: "white",
              cursor: loading ? "not-allowed" : "pointer",
              opacity: loading ? 0.7 : 1,
            }}
          >
            {loading ? "..." : isRegister ? "Înregistrează" : "Intră"}
          </button>
        </form>

        <div style={{ marginTop: 20, textAlign: "center" }}>
          <button
            onClick={() => {
              setIsRegister(!isRegister);
              setErr(null);
            }}
            style={{
              background: "none",
              border: "none",
              color: "#6366f1",
              cursor: "pointer",
              textDecoration: "underline",
              fontSize: 14,
            }}
          >
            {isRegister
              ? "Ai deja cont? Loghează-te"
              : "Nu ai cont? Înregistrează-te"}
          </button>
        </div>
      </div>
    </div>
  );
}
