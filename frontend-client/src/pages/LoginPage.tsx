import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../api";

export default function LoginPage() {
  const nav = useNavigate();
  const [email, setEmail] = useState("admin1@restaurant1.com");
  const [password, setPassword] = useState("admin123");
  const [err, setErr] = useState<string | null>(null);

  async function onLogin(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    try {
      const res = await api.post("/auth/login", { email, password });
      localStorage.setItem("token", res.data.token);
      nav("/restaurants");
    } catch (e: any) {
      setErr(e.response?.data?.message || e.message || "Login failed");
    }
  }

  return (
    <div style={{ minHeight: "100vh", backgroundColor: "#f8fafc", display: "flex", alignItems: "center", justifyContent: "center", padding: 16 }}>
      <div style={{ backgroundColor: "white", borderRadius: 16, padding: 32, width: "100%", maxWidth: 400, boxShadow: "0 4px 20px rgba(0,0,0,0.1)" }}>
        <h2 style={{ margin: "0 0 24px 0", textAlign: "center", fontSize: 24, fontWeight: 700, color: "#1e293b" }}>Login</h2>
        <form onSubmit={onLogin} style={{ display: "grid", gap: 16 }}>
          <div>
            <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase" }}>Email</label>
            <input
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="email"
              style={{ width: "100%", padding: "12px 16px", borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 14, boxSizing: "border-box" }}
            />
          </div>
          <div>
            <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase" }}>Parolă</label>
            <input
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="password"
              type="password"
              style={{ width: "100%", padding: "12px 16px", borderRadius: 8, border: "1px solid #e2e8f0", fontSize: 14, boxSizing: "border-box" }}
            />
          </div>
          {err && <div style={{ color: "#dc2626", fontSize: 14, padding: "12px 16px", backgroundColor: "#fef2f2", borderRadius: 8 }}>{err}</div>}
          <button
            type="submit"
            style={{
              padding: "12px 24px",
              fontSize: 16,
              fontWeight: 600,
              borderRadius: 8,
              border: "none",
              backgroundColor: "#6366f1",
              color: "white",
              cursor: "pointer",
            }}
          >
            Intră
          </button>
        </form>
      </div>
    </div>
  );
}
