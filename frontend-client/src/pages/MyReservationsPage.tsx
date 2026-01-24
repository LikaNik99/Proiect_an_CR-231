import { useEffect, useState } from "react";
import { api } from "../api";

type ReservationDto = {
  id: number;
  restaurantId: number;
  restaurantName: string;
  tableNo: number;
  startDt: string;
  endDt: string;
  persons: number;
  durationMin: number;
  status: string;
};

function formatTime(dateTimeStr: string) {
  const date = new Date(dateTimeStr);
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${hours}:${minutes}`;
}

export default function MyReservationsPage() {
  const [items, setItems] = useState<ReservationDto[]>([]);
  const [err, setErr] = useState<string | null>(null);

  async function load() {
    setErr(null);
    try {
      const res = await api.get("/api/me/reservations");
      console.log("API response:", res.data);
      setItems(res.data);
    } catch (e: any) {
      setErr(e?.response?.data?.message ?? "Cannot load reservations");
    }
  }

  useEffect(() => {
    load();
  }, []);

  return (
    <div style={{ minHeight: "100vh", backgroundColor: "#f8fafc", padding: "24px 16px" }}>
      <div style={{ maxWidth: 1000, margin: "0 auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <h2 style={{ margin: 0, fontSize: 28, fontWeight: 700, color: "#1e293b" }}>
            Rezervările mele
          </h2>
          <button
            onClick={load}
            style={{
              padding: "8px 16px",
              backgroundColor: "#6366f1",
              color: "white",
              border: "none",
              borderRadius: 8,
              fontSize: 14,
              fontWeight: 500,
              cursor: "pointer",
            }}
          >
            Refresh
          </button>
        </div>

        {err && (
          <div
            style={{
              backgroundColor: "#fef2f2",
              color: "#dc2626",
              padding: "16px 20px",
              borderRadius: 8,
              marginBottom: 24,
              fontSize: 14,
            }}
          >
            {err}
          </div>
        )}

        <div style={{ display: "grid", gap: 16 }}>
          {items.map((r) => (
            <div
              key={r.id}
              style={{
                backgroundColor: "white",
                borderRadius: 12,
                overflow: "hidden",
                boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
              }}
            >
              <div
                style={{
                  height: 6,
                  background: r.status === "CONFIRMED"
                    ? "linear-gradient(90deg, #16a34a 0%, #22c55e 100%)"
                    : r.status === "CANCELLED"
                    ? "linear-gradient(90deg, #dc2626 0%, #ef4444 100%)"
                    : "linear-gradient(90deg, #f59e0b 0%, #fbbf24 100%)",
                }}
              />
              <div style={{ padding: 20 }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                  <div style={{ fontSize: 18, fontWeight: 600, color: "#1e293b" }}>
                    Rezervare#{r.id}
                  </div>
                  <span
                    style={{
                      padding: "4px 12px",
                      borderRadius: 20,
                      fontSize: 12,
                      fontWeight: 600,
                      backgroundColor: r.status === "CONFIRMED"
                        ? "#f0fdf4"
                        : r.status === "CANCELLED"
                        ? "#fef2f2"
                        : "#fffbeb",
                      color: r.status === "CONFIRMED"
                        ? "#16a34a"
                        : r.status === "CANCELLED"
                        ? "#dc2626"
                        : "#d97706",
                    }}
                  >
                    {r.status}
                  </span>
                </div>

                <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
                  <span
                    style={{
                      backgroundColor: "#f0fdf4",
                      color: "#16a34a",
                      padding: "4px 10px",
                      borderRadius: 6,
                      fontSize: 12,
                      fontWeight: 500,
                    }}
                  >
                    {r.restaurantName}
                  </span>
                  <span
                    style={{
                      backgroundColor: "#f1f5f9",
                      color: "#475569",
                      padding: "4px 10px",
                      borderRadius: 6,
                      fontSize: 12,
                      fontWeight: 500,
                    }}
                  >
                    Masa {r.tableNo}
                  </span>
                </div>

                <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 12 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{ fontSize: 16 }}>🕐</span>
                    <span style={{ color: "#475569", fontSize: 14 }}>
                      <span style={{ color: "#64748b", fontSize: 12, display: "block" }}>Start</span>
                      {formatTime(r.startDt)}
                    </span>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{ fontSize: 16 }}>⏰</span>
                    <span style={{ color: "#475569", fontSize: 14 }}>
                      <span style={{ color: "#64748b", fontSize: 12, display: "block" }}>Sfârșit</span>
                      {formatTime(r.endDt)}
                    </span>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{ fontSize: 16 }}>👥</span>
                    <span style={{ color: "#475569", fontSize: 14 }}>
                      <span style={{ color: "#64748b", fontSize: 12, display: "block" }}>Persoane</span>
                      {r.persons}
                    </span>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{ fontSize: 16 }}>⏱️</span>
                    <span style={{ color: "#475569", fontSize: 14 }}>
                      <span style={{ color: "#64748b", fontSize: 12, display: "block" }}>Durata</span>
                      {r.durationMin} min
                    </span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {items.length === 0 && !err && (
          <div
            style={{
              textAlign: "center",
              padding: 60,
              backgroundColor: "white",
              borderRadius: 12,
              boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
            }}
          >
            <div style={{ fontSize: 48, marginBottom: 16 }}>📋</div>
            <p style={{ margin: 0, fontSize: 16, color: "#64748b" }}>
              Nu ai nicio rezervare.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
