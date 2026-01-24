import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../api";
import { clearToken, getRole, getAdminRestaurantIds } from "../lib/auth";
import type { RestaurantDto } from "../types";

const CUISINES = ["Românească", "Italiană", "Mediteraneană", "Internațională", "Asiatică"];
const PRICE_RANGES = ["$", "$$", "$$$"];

function StarRating({ rating }: { rating: number }) {
  return (
    <div style={{ display: "flex", gap: 2 }}>
      {[1, 2, 3, 4, 5].map((star) => (
        <span
          key={star}
          style={{
            color: star <= rating ? "#fbbf24" : "#d1d5db",
            fontSize: 16,
          }}
        >
          ★
        </span>
      ))}
    </div>
  );
}

function getRandomCuisine() {
  return CUISINES[Math.floor(Math.random() * CUISINES.length)];
}

function getRandomPrice() {
  return PRICE_RANGES[Math.floor(Math.random() * PRICE_RANGES.length)];
}

function getRandomRating() {
  return Math.floor(Math.random() * 2) + 3;
}

export default function Restaurants() {
  const nav = useNavigate();
  const [items, setItems] = useState<RestaurantDto[]>([]);
  const [filteredItems, setFilteredItems] = useState<RestaurantDto[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedCuisine, setSelectedCuisine] = useState<string>("");
  const [selectedPrice, setSelectedPrice] = useState<string>("");
  const role = getRole();
  const adminRestaurantIds = getAdminRestaurantIds();

  useEffect(() => {
    console.log("Loading restaurants...");
    api.get<RestaurantDto[]>("/api/restaurants")
      .then((res) => {
        console.log("Restaurants loaded:", res.data);
        setItems(res.data);
        setFilteredItems(res.data);
        setLoading(false);
      })
      .catch((e: any) => {
        console.error("Error loading restaurants:", e);
        setErr(e?.response?.data?.message ?? e.message);
        setLoading(false);
      });
  }, []);

  useEffect(() => {
    let filtered = items;

    if (searchTerm) {
      filtered = filtered.filter((r) =>
        r.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.address.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (selectedCuisine) {
      filtered = filtered.filter((r) => r.cuisine === selectedCuisine);
    }

    if (selectedPrice) {
      filtered = filtered.filter((r) => r.priceSign === selectedPrice);
    }

    setFilteredItems(filtered);
  }, [searchTerm, selectedCuisine, selectedPrice, items]);

  function logout() {
    clearToken();
    nav("/login");
  }

  return (
    <div style={{ minHeight: "100vh", backgroundColor: "#f8fafc", padding: "24px 16px" }}>
      <div style={{ maxWidth: 1200, margin: "0 auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 32 }}>
          <h1 style={{ fontSize: 36, fontWeight: 700, color: "#1e293b", margin: 0 }}>Restaurante</h1>
          <div style={{ display: "flex", gap: 12 }}>
            <Link
              to="/me/reservations"
              style={{
                color: "#6366f1",
                textDecoration: "none",
                fontWeight: 500,
                display: "flex",
                alignItems: "center",
                gap: 4,
                fontSize: 15,
              }}
            >
              Rezervările mele →
            </Link>
            {(role === "ADMIN" || role === "SUPER_ADMIN") && adminRestaurantIds.length > 0 && (
              <Link
                to="/admin"
                style={{
                  color: "#10b981",
                  textDecoration: "none",
                  fontWeight: 500,
                  display: "flex",
                  alignItems: "center",
                  gap: 4,
                  fontSize: 15,
                }}
              >
                Admin Panel →
              </Link>
            )}
            <button
              onClick={logout}
              style={{
                color: "#ef4444",
                textDecoration: "none",
                fontWeight: 500,
                fontSize: 15,
                background: "none",
                border: "none",
                cursor: "pointer",
              }}
            >
              Logout
            </button>
          </div>
        </div>

        <div style={{ backgroundColor: "white", borderRadius: 12, overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.1)", marginBottom: 24 }}>
          <div style={{ height: 8, background: "linear-gradient(90deg, #667eea 0%, #764ba2 100%)" }} />
          <div style={{ padding: 24 }}>
            <div style={{ display: "flex", gap: 16, flexWrap: "wrap" }}>
              <div style={{ flex: 1, minWidth: 200 }}>
                <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase", letterSpacing: 0.5 }}>
                  Caută
                </label>
                <input
                  type="text"
                  placeholder="Caută restaurant..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "12px 16px",
                    borderRadius: 8,
                    border: "1px solid #e2e8f0",
                    fontSize: 14,
                    outline: "none",
                    boxSizing: "border-box",
                    color: "#1e293b",
                    backgroundColor: "white",
                  }}
                />
              </div>
              <div style={{ flex: "0 0 180px" }}>
                <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase", letterSpacing: 0.5 }}>
                  Bucătărie
                </label>
                <select
                  value={selectedCuisine}
                  onChange={(e) => setSelectedCuisine(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "12px 16px",
                    borderRadius: 8,
                    border: "1px solid #e2e8f0",
                    fontSize: 14,
                    backgroundColor: "white",
                    cursor: "pointer",
                    boxSizing: "border-box",
                    color: "#1e293b",
                  }}
                >
                  <option value="">Toate</option>
                  {Array.from(new Set(items.map((r) => r.cuisine).filter(Boolean))).map((cuisine) => (
                    <option key={cuisine} value={cuisine}>{cuisine}</option>
                  ))}
                </select>
              </div>
              <div style={{ flex: "0 0 140px" }}>
                <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase", letterSpacing: 0.5 }}>
                  Preț
                </label>
                <select
                  value={selectedPrice}
                  onChange={(e) => setSelectedPrice(e.target.value)}
                  style={{
                    width: "100%",
                    padding: "12px 16px",
                    borderRadius: 8,
                    border: "1px solid #e2e8f0",
                    fontSize: 14,
                    backgroundColor: "white",
                    cursor: "pointer",
                    boxSizing: "border-box",
                    color: "#1e293b",
                  }}
                >
                  <option value="">Toate</option>
                  {Array.from(new Set(items.map((r) => r.priceSign).filter(Boolean))).map((price) => (
                    <option key={price} value={price}>{price}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>
        </div>

        {err && (
          <div
            style={{
              backgroundColor: "#fef2f2",
              color: "#dc2626",
              padding: "12px 16px",
              borderRadius: 8,
              marginBottom: 24,
            }}
          >
            {err}
          </div>
        )}

        {loading ? (
            <div style={{ display: "grid", gap: 24, gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))" }}>
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  style={{
                    backgroundColor: "white",
                    borderRadius: 12,
                    overflow: "hidden",
                    boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
                  }}
                >
                  <div style={{ height: 180, backgroundColor: "#e2e8f0", animation: "pulse 1.5s infinite" }} />
                  <div style={{ padding: 20 }}>
                    <div style={{ height: 24, backgroundColor: "#e2e8f0", borderRadius: 4, marginBottom: 16, animation: "pulse 1.5s infinite" }} />
                    <div style={{ height: 16, width: "60%", backgroundColor: "#e2e8f0", borderRadius: 4, marginBottom: 12, animation: "pulse 1.5s infinite" }} />
                    <div style={{ height: 16, width: "80%", backgroundColor: "#e2e8f0", borderRadius: 4, marginBottom: 8, animation: "pulse 1.5s infinite" }} />
                    <div style={{ height: 16, width: "50%", backgroundColor: "#e2e8f0", borderRadius: 4, animation: "pulse 1.5s infinite" }} />
                  </div>
                </div>
              ))}
            </div>
        ) : filteredItems.length === 0 ? (
          <div
            style={{
              textAlign: "center",
              padding: 80,
              color: "#64748b",
              backgroundColor: "white",
              borderRadius: 12,
              boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
            }}
          >
            <div style={{ fontSize: 64, marginBottom: 24 }}>🍽️</div>
            <p style={{ fontSize: 20, marginBottom: 8, color: "#334155" }}>Nu s-au găsit restaurante</p>
            <p style={{ fontSize: 14 }}>Încearcă alte criterii de căutare</p>
          </div>
        ) : (
          <div style={{ display: "grid", gap: 24, gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))" }}>
            {filteredItems.map((r) => {
              const cuisine = r.cuisine || getRandomCuisine();
              const price = r.priceSign || getRandomPrice();
              const rating = getRandomRating();

              return (
                <Link
                  key={r.id}
                  to={`/restaurants/${r.id}`}
                  style={{
                    textDecoration: "none",
                    backgroundColor: "white",
                    borderRadius: 12,
                    overflow: "hidden",
                    boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
                    transition: "transform 0.2s, box-shadow 0.2s",
                    display: "block",
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.transform = "translateY(-4px)";
                    e.currentTarget.style.boxShadow = "0 10px 25px rgba(0,0,0,0.15)";
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow = "0 1px 3px rgba(0,0,0,0.1)";
                  }}
                >
                  {r.imageUrl ? (
                    <div
                      style={{
                        height: 180,
                        backgroundColor: "#f1f5f9",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        position: "relative",
                        overflow: "hidden",
                      }}
                    >
                      <img
                        src={r.imageUrl}
                        alt={r.name}
                        style={{
                          width: "100%",
                          height: "100%",
                          objectFit: "cover",
                        }}
                        onError={(e) => {
                          const target = e.target as HTMLImageElement;
                          target.style.display = "none";
                        }}
                      />
                      <div
                        style={{
                          position: "absolute",
                          top: 16,
                          right: 16,
                          backgroundColor: "white",
                          padding: "6px 12px",
                          borderRadius: 8,
                          fontSize: 14,
                          fontWeight: 600,
                          color: "#1e293b",
                        }}
                      >
                        {price}
                      </div>
                    </div>
                  ) : (
                    <div
                      style={{
                        height: 180,
                        background: `linear-gradient(135deg, #667eea 0%, #764ba2 100%)`,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        position: "relative",
                      }}
                    >
                      <span style={{ fontSize: 64, opacity: 0.3 }}>🍽️</span>
                      <div
                        style={{
                          position: "absolute",
                          top: 16,
                          right: 16,
                          backgroundColor: "white",
                          padding: "6px 12px",
                          borderRadius: 8,
                          fontSize: 14,
                          fontWeight: 600,
                          color: "#1e293b",
                        }}
                      >
                        {price}
                      </div>
                    </div>
                  )}
                  <div style={{ padding: 20 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
                      <h3 style={{ margin: 0, fontSize: 20, fontWeight: 600, color: "#1e293b" }}>{r.name}</h3>
                      <StarRating rating={rating} />
                    </div>
                    <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
                      <span
                        style={{
                          backgroundColor: "#f0fdf4",
                          color: "#16a34a",
                          padding: "6px 12px",
                          borderRadius: 20,
                          fontSize: 13,
                          fontWeight: 500,
                        }}
                      >
                        {cuisine}
                      </span>
                    </div>
                    <p style={{ margin: 0, fontSize: 14, color: "#64748b", marginBottom: 16 }}>
                      {r.address}
                    </p>
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 8,
                        fontSize: 14,
                        color: "#64748b",
                      }}
                    >
                      <span>🕐</span>
                      <span>
                        {r.openTime} - {r.closeTime}
                        {r.crossesMidnight && " (non-stop)"}
                      </span>
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
