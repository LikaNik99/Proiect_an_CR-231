import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { api } from "../lib/api";
import { clearToken } from "../lib/auth";

function formatTime(dateTimeStr: string) {
  const date = new Date(dateTimeStr);
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${hours}:${minutes}`;
}

type ReservationDto = {
  id: number;
  restaurantId: number;
  restaurantName: string;
  tableId: number;
  tableNo: number;
  startDt: string;
  endDt: string;
  persons: number;
  durationMin: number;
  status: string;
  customerName: string;
  customerEmail: string;
};

type RestaurantDto = {
  id: number;
  name: string;
};

export default function AdminPage() {
  const nav = useNavigate();
  const [reservations, setReservations] = useState<ReservationDto[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [restaurants, setRestaurants] = useState<RestaurantDto[]>([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState<string>("");

  useEffect(() => {
    loadRestaurants();
  }, []);

  async function loadRestaurants() {
    try {
      const res = await api<RestaurantDto[]>("/restaurants");
      setRestaurants(res);
      if (res.length > 0) {
        setSelectedRestaurant(String(res[0].id));
      }
    } catch (e: any) {
      console.error("Error loading restaurants:", e);
      setErr("Failed to load restaurants: " + e.message);
    }
  }

  async function loadReservations() {
    if (!selectedRestaurant) return;
    setLoading(true);
    setErr(null);
    try {
      const res = await api<ReservationDto[]>(
        `/admin/reservations?restaurantId=${selectedRestaurant}`
      );
      setReservations(res);
    } catch (e: any) {
      setErr("Failed to load reservations: " + e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (selectedRestaurant) {
      loadReservations();
    }
  }, [selectedRestaurant]);

  async function updateStatus(reservationId: number, newStatus: string) {
    setErr(null);
    try {
      await api<ReservationDto>(`/admin/reservations/${reservationId}?restaurantId=${selectedRestaurant}&status=${newStatus}`, {
        method: "PATCH",
      });
      await loadReservations();
    } catch (e: any) {
      setErr("Failed to update status: " + e.message);
    }
  }

  function logout() {
    clearToken();
    nav("/login");
  }

  function refresh() {
    loadRestaurants();
    if (selectedRestaurant) {
      loadReservations();
    }
  }

  return (
    <div style={{ padding: 20, fontFamily: "system-ui" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
        <h1 style={{ margin: 0 }}>Admin Panel</h1>
        <div style={{ display: "flex", gap: 10 }}>
          <button onClick={refresh} style={{ padding: "8px 16px", backgroundColor: "#6366f1", color: "white", border: "none", borderRadius: 4, cursor: "pointer" }}>
            Refresh
          </button>
          <button onClick={logout} style={{ padding: "8px 16px", backgroundColor: "#ef4444", color: "white", border: "none", borderRadius: 4, cursor: "pointer" }}>
            Logout
          </button>
        </div>
      </div>

      <div style={{ marginBottom: 20 }}>
        <label style={{ marginRight: 10 }}>Restaurant:</label>
        <select
          value={selectedRestaurant}
          onChange={(e) => setSelectedRestaurant(e.target.value)}
          style={{ padding: 8, borderRadius: 4, border: "1px solid #ccc" }}
        >
          {restaurants.map((r) => (
            <option key={r.id} value={r.id}>{r.name}</option>
          ))}
        </select>
      </div>

      {err && (
        <div style={{ backgroundColor: "#fee", color: "#c00", padding: 12, borderRadius: 4, marginBottom: 20 }}>
          {err}
        </div>
      )}

      {loading ? (
        <div>Loading...</div>
      ) : (
        <div>
          <h3>Rezervari ({reservations.length})</h3>
          {reservations.length === 0 ? (
            <p>Nu exista rezervari.</p>
          ) : (
            reservations.map((r) => (
              <div key={r.id} style={{ border: "1px solid #ddd", borderRadius: 8, padding: 16, marginBottom: 12 }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "start" }}>
                  <div>
                    <strong>Rezervare#{r.id}</strong> - {r.customerName}
                    <div style={{ color: "#666", fontSize: 14 }}>Masa: {r.tableNo} | Persoane: {r.persons}</div>
                    <div style={{ color: "#666", fontSize: 14 }}>Start: {formatTime(r.startDt)} | Sfarsit: {formatTime(r.endDt)}</div>
                  </div>
                  <select
                    value={r.status}
                    onChange={(e) => updateStatus(r.id, e.target.value)}
                    style={{ padding: 6, borderRadius: 4 }}
                  >
                    <option value="PENDING">PENDING</option>
                    <option value="CONFIRMED">CONFIRMED</option>
                    <option value="CANCELLED">CANCELLED</option>
                    <option value="COMPLETED">COMPLETED</option>
                  </select>
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}
