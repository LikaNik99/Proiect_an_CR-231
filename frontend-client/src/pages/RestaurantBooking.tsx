import { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, normalizeRomanianChars } from "../lib/api";
import type { CreateReservationRequest, ReservationDto, RestaurantDto } from "../types";

const DURATIONS = [60, 90, 120, 150] as const;

function yyyyMmDd(d: Date) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

function formatTime(dateTimeStr: string) {
  const date = new Date(dateTimeStr);
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${hours}:${minutes}`;
}

function formatDate(dateStr: string) {
  const date = new Date(dateStr);
  return date.toLocaleDateString("ro-RO", { weekday: "long", day: "numeric", month: "long" });
}

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

function Modal({
  isOpen,
  onClose,
  onConfirm,
  title,
  children,
  confirmText = "Confirmă",
  cancelText = "Anulează",
  isDestructive = false,
}: {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  children: React.ReactNode;
  confirmText?: string;
  cancelText?: string;
  isDestructive?: boolean;
}) {
  if (!isOpen) return null;

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: "rgba(0,0,0,0.5)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1000,
        animation: "fadeIn 0.2s ease-out",
      }}
      onClick={onClose}
    >
        <div
          style={{
            backgroundColor: "white",
            borderRadius: 16,
            padding: 24,
            maxWidth: 420,
            width: "90%",
            maxHeight: "90vh",
            overflow: "auto",
            boxShadow: "0 20px 40px rgba(0,0,0,0.2)",
            animation: "slideUp 0.2s ease-out",
          }}
        onClick={(e) => e.stopPropagation()}
      >
        <h3 style={{ margin: "0 0 16px 0", fontSize: 20, fontWeight: 600, color: "#1e293b" }}>
          {title}
        </h3>
        <div style={{ marginBottom: 24, color: "#475569", fontSize: 15, lineHeight: 1.6 }}>
          {children}
        </div>
        <div style={{ display: "flex", gap: 12, justifyContent: "flex-end" }}>
          <button
            onClick={onClose}
            style={{
              padding: "10px 20px",
              backgroundColor: "#f1f5f9",
              color: "#475569",
              border: "none",
              borderRadius: 8,
              fontSize: 14,
              fontWeight: 500,
              cursor: "pointer",
            }}
          >
            {cancelText}
          </button>
          <button
            onClick={() => {
              onConfirm();
              onClose();
            }}
            style={{
              padding: "10px 20px",
              backgroundColor: isDestructive ? "#ef4444" : "#6366f1",
              color: "white",
              border: "none",
              borderRadius: 8,
              fontSize: 14,
              fontWeight: 500,
              cursor: "pointer",
            }}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function RestaurantBooking() {
  const { id } = useParams();
  const restaurantId = Number(id);

  const today = useMemo(() => yyyyMmDd(new Date()), []);
  const [restaurant, setRestaurant] = useState<RestaurantDto | null>(null);

  const [date, setDate] = useState(today);
  const [persons, setPersons] = useState(2);
  const [durationMin, setDurationMin] = useState<(typeof DURATIONS)[number]>(90);

  const [slots, setSlots] = useState<string[]>([]);
  const [selectedSlot, setSelectedSlot] = useState<string | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [showConfirmModal, setShowConfirmModal] = useState(false);
  const [showResultModal, setShowResultModal] = useState(false);
  const [resultMessage, setResultMessage] = useState<{ type: "success" | "error"; text: string; isTableBooked?: boolean } | null>(null);

  useEffect(() => {
    api<RestaurantDto>(`/api/restaurants/${restaurantId}`)
      .then(setRestaurant)
      .catch((e) => setErr(e.message));
  }, [restaurantId]);

  async function loadAvailability() {
    setErr(null);
    setLoading(true);
    setSelectedSlot(null);
    try {
      const res = await api<string[]>(
        `/api/restaurants/${restaurantId}/availability?date=${date}&persons=${persons}&duration=${durationMin}`,
        { method: "GET" }
      );
      setSlots(res);
    } catch (e: any) {
      setErr(e.message);
      setSlots([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!Number.isFinite(restaurantId)) return;
    loadAvailability();
  }, [restaurantId, date, persons, durationMin]);

  async function confirmBooking() {
    if (!selectedSlot) return;

    setErr(null);
    const body: CreateReservationRequest = {
      restaurantId,
      startDt: selectedSlot,
      persons,
      durationMin,
    };

    try {
      const res = await api<ReservationDto>("/reservations", {
        method: "POST",
        body: JSON.stringify(body),
      });
      setResultMessage({
        type: "success",
        text: `Rezervare creată cu succes! Masa ${res.tableNo}, Status: ${res.status}`,
      });
      setShowResultModal(true);
      await loadAvailability();
    } catch (e: any) {
      let errorText = e.message || "A apărut o eroare la crearea rezervării.";
      errorText = errorText.replace(/^\d+\s+\S+\s+/, "");
      if (errorText.length > 200) {
        errorText = errorText.substring(0, 200) + "...";
      }
      const isTableBooked = errorText.includes("deja rezervată") || errorText.includes("already booked");
      setResultMessage({
        type: "error",
        text: errorText,
        isTableBooked: isTableBooked
      });
      setShowResultModal(true);
    }
  }

  const cuisine = restaurant?.cuisine || "Românească";
  const price = restaurant?.priceSign || "$$";
  const rating = 4;

  return (
    <div style={{ minHeight: "100vh", backgroundColor: "#f8fafc", padding: "24px 16px" }}>
      <div style={{ maxWidth: 1200, margin: "0 auto" }}>
        <Modal
          isOpen={showConfirmModal}
          onClose={() => setShowConfirmModal(false)}
          onConfirm={confirmBooking}
          title="Confirmă rezervarea"
        >
          <p style={{ marginBottom: 16 }}>
            Ești sigur că vrei să faci această rezervare?
          </p>
          <div
            style={{
              backgroundColor: "#f8fafc",
              borderRadius: 8,
              padding: 16,
              marginBottom: 8,
            }}
          >
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ color: "#64748b" }}>Restaurant:</span>
              <span style={{ fontWeight: 500, color: "#1e293b" }}>{restaurant?.name}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ color: "#64748b" }}>Data:</span>
              <span style={{ fontWeight: 500, color: "#1e293b" }}>{formatDate(date)}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ color: "#64748b" }}>Ora:</span>
              <span style={{ fontWeight: 500, color: "#1e293b" }}>{formatTime(selectedSlot || "")}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
              <span style={{ color: "#64748b" }}>Persoane:</span>
              <span style={{ fontWeight: 500, color: "#1e293b" }}>{persons}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between" }}>
              <span style={{ color: "#64748b" }}>Durata:</span>
              <span style={{ fontWeight: 500, color: "#1e293b" }}>{durationMin} minute</span>
            </div>
          </div>
        </Modal>

        <Modal
          isOpen={showResultModal}
          onClose={() => {
            setShowResultModal(false);
            setResultMessage(null);
          }}
          onConfirm={() => {
            setShowResultModal(false);
            setResultMessage(null);
          }}
          title={resultMessage?.type === "success" ? "Succes!" : resultMessage?.isTableBooked ? "Masa este deja rezervată" : "Eroare"}
          confirmText="Închide"
          isDestructive={resultMessage?.type === "error"}
        >
          <div
            style={{
              display: "flex",
              alignItems: "flex-start",
              gap: 12,
              padding: "12px 16px",
              backgroundColor: resultMessage?.type === "success" ? "#f0fdf4" : "#fef2f2",
              borderRadius: 8,
              marginBottom: 8,
            }}
          >
            <span style={{ fontSize: 24, flexShrink: 0 }}>{resultMessage?.type === "success" ? "✅" : resultMessage?.isTableBooked ? "⚠️" : "❌"}</span>
            <span style={{ color: resultMessage?.type === "success" ? "#16a34a" : resultMessage?.isTableBooked ? "#d97706" : "#dc2626", fontWeight: 500, wordWrap: "break-word", overflowWrap: "break-word", lineHeight: 1.5 }}>
              {resultMessage?.text}
            </span>
          </div>
          {resultMessage?.isTableBooked && (
            <div style={{ fontSize: 13, color: "#64748b", marginTop: 12, padding: 12, backgroundColor: "#fffbeb", borderRadius: 8, border: "1px solid #fcd34d" }}>
              <strong>Sfat:</strong> Încearcă să selectezi o altă oră sau o durată diferită.
            </div>
          )}
        </Modal>

        <div style={{ marginBottom: 24 }}>
          <Link
            to="/restaurants"
            style={{
              color: "#6366f1",
              textDecoration: "none",
              fontWeight: 500,
              display: "inline-flex",
              alignItems: "center",
              gap: 4,
              fontSize: 14,
            }}
          >
            ← Restaurante
          </Link>
        </div>

        <div
          style={{
            backgroundColor: "white",
            borderRadius: 12,
            overflow: "hidden",
            boxShadow: "0 1px 3px rgba(0,0,0,0.1)",
            marginBottom: 24,
          }}
        >
          {restaurant?.imageUrl ? (
            <div
              style={{
                height: 200,
                backgroundColor: "#f1f5f9",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                position: "relative",
                overflow: "hidden",
              }}
            >
              <img
                src={restaurant.imageUrl}
                alt={restaurant.name}
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
                  padding: "8px 14px",
                  borderRadius: 8,
                  fontSize: 16,
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
                height: 200,
                background: `linear-gradient(135deg, #667eea 0%, #764ba2 100%)`,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                position: "relative",
              }}
            >
              <span style={{ fontSize: 80, opacity: 0.3 }}>🍽️</span>
              <div
                style={{
                  position: "absolute",
                  top: 16,
                  right: 16,
                  backgroundColor: "white",
                  padding: "8px 14px",
                  borderRadius: 8,
                  fontSize: 16,
                  fontWeight: 600,
                  color: "#1e293b",
                }}
              >
                {price}
              </div>
            </div>
          )}
          <div style={{ padding: 24 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 12 }}>
              <h1 style={{ margin: 0, fontSize: 28, fontWeight: 700, color: "#1e293b" }}>
                {restaurant ? restaurant.name : `Restaurant #${restaurantId}`}
              </h1>
              <StarRating rating={rating} />
            </div>
            <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
              <span
                style={{
                  backgroundColor: "#f0fdf4",
                  color: "#16a34a",
                  padding: "6px 14px",
                  borderRadius: 20,
                  fontSize: 13,
                  fontWeight: 500,
                }}
              >
                {cuisine}
              </span>
            </div>
            <p style={{ margin: 0, fontSize: 15, color: "#64748b", marginBottom: 16 }}>
              {restaurant?.address ? normalizeRomanianChars(restaurant.address) : "Adresa nu este disponibila"}
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
                {restaurant?.openTime} - {restaurant?.closeTime}
                {restaurant?.crossesMidnight && " (non-stop)"}
              </span>
            </div>
          </div>
        </div>

        <div style={{ backgroundColor: "white", borderRadius: 12, overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.1)", marginBottom: 24 }}>
          <div style={{ height: 8, background: "linear-gradient(90deg, #667eea 0%, #764ba2 100%)" }} />
          <div style={{ padding: 24 }}>
            <h2 style={{ margin: "0 0 20px 0", fontSize: 20, fontWeight: 600, color: "#1e293b" }}>
              Configurează rezervarea
            </h2>
            <div style={{ display: "flex", gap: 20, flexWrap: "wrap" }}>
              <div style={{ flex: "0 0 180px" }}>
                <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase", letterSpacing: 0.5 }}>
                  Data
                </label>
                <input
                  type="date"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
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
              <div style={{ flex: "0 0 140px" }}>
                <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase", letterSpacing: 0.5 }}>
                  Persoane
                </label>
                <input
                  type="number"
                  min={1}
                  max={20}
                  value={persons}
                  onChange={(e) => setPersons(Number(e.target.value))}
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
              <div style={{ flex: "0 0 160px" }}>
                <label style={{ display: "block", fontSize: 12, fontWeight: 600, color: "#64748b", marginBottom: 6, textTransform: "uppercase", letterSpacing: 0.5 }}>
                  Durată
                </label>
                <select
                  value={durationMin}
                  onChange={(e) => setDurationMin(Number(e.target.value) as any)}
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
                  {DURATIONS.map((d) => (
                    <option key={d} value={d}>{d} minute</option>
                  ))}
                </select>
              </div>
              <div style={{ flex: "0 0 auto", alignSelf: "flex-end" }}>
                <button
                  onClick={loadAvailability}
                  disabled={loading}
                  style={{
                    padding: "12px 24px",
                    backgroundColor: "#6366f1",
                    color: "white",
                    border: "none",
                    borderRadius: 8,
                    fontSize: 14,
                    fontWeight: 500,
                    cursor: loading ? "not-allowed" : "pointer",
                    opacity: loading ? 0.7 : 1,
                  }}
                >
                  {loading ? "Se încarcă..." : "Caută ore disponibile"}
                </button>
              </div>
            </div>
          </div>
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

        <div style={{ backgroundColor: "white", borderRadius: 12, overflow: "hidden", boxShadow: "0 1px 3px rgba(0,0,0,0.1)" }}>
          <div style={{ height: 8, background: "linear-gradient(90deg, #667eea 0%, #764ba2 100%)" }} />
          <div style={{ padding: 24 }}>
            <h2 style={{ margin: "0 0 20px 0", fontSize: 20, fontWeight: 600, color: "#1e293b" }}>
              Ore disponibile
            </h2>
            {slots.length === 0 ? (
              <div style={{ textAlign: "center", padding: 40, color: "#64748b" }}>
                <div style={{ fontSize: 48, marginBottom: 16 }}>📅</div>
                <p style={{ margin: 0, fontSize: 16 }}>Niciun slot disponibil pentru parametrii aleși.</p>
              </div>
            ) : (
              <>
                <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(120px, 1fr))", gap: 10, marginBottom: selectedSlot ? 20 : 0 }}>
                  {slots.map((s) => (
                    <button
                      key={s}
                      onClick={() => setSelectedSlot(s)}
                      style={{
                        padding: "14px 16px",
                        backgroundColor: selectedSlot === s ? "#6366f1" : "#f8fafc",
                        border: selectedSlot === s ? "2px solid #6366f1" : "1px solid #e2e8f0",
                        borderRadius: 10,
                        fontSize: 15,
                        fontWeight: 500,
                        color: selectedSlot === s ? "white" : "#1e293b",
                        cursor: "pointer",
                        transition: "all 0.2s",
                      }}
                      onMouseEnter={(e) => {
                        if (selectedSlot !== s) {
                          e.currentTarget.style.backgroundColor = "#e0e7ff";
                          e.currentTarget.style.borderColor = "#6366f1";
                        }
                      }}
                      onMouseLeave={(e) => {
                        if (selectedSlot !== s) {
                          e.currentTarget.style.backgroundColor = "#f8fafc";
                          e.currentTarget.style.borderColor = "#e2e8f0";
                        }
                      }}
                    >
                      {formatTime(s)}
                    </button>
                  ))}
                </div>
                {selectedSlot && (
                  <div
                    style={{
                      display: "flex",
                      gap: 12,
                      alignItems: "center",
                      padding: "16px 20px",
                      backgroundColor: "#f0fdf4",
                      borderRadius: 10,
                      border: "1px solid #bbf7d0",
                      animation: "fadeIn 0.2s ease-out",
                    }}
                  >
                    <span style={{ flex: 1, fontSize: 15, color: "#166534", fontWeight: 500 }}>
                      Ai selectat ora <strong>{formatTime(selectedSlot)}</strong>
                    </span>
                    <button
                      onClick={() => setShowConfirmModal(true)}
                      style={{
                        padding: "12px 24px",
                        backgroundColor: "#16a34a",
                        color: "white",
                        border: "none",
                        borderRadius: 8,
                        fontSize: 14,
                        fontWeight: 500,
                        cursor: "pointer",
                      }}
                    >
                      Confirmă rezervarea
                    </button>
                    <button
                      onClick={() => setSelectedSlot(null)}
                      style={{
                        padding: "12px 20px",
                        backgroundColor: "white",
                        color: "#64748b",
                        border: "1px solid #e2e8f0",
                        borderRadius: 8,
                        fontSize: 14,
                        fontWeight: 500,
                        cursor: "pointer",
                      }}
                    >
                      Anulează
                    </button>
                  </div>
                )}
              </>
            )}
          </div>
        </div>

        <div style={{ marginTop: 24, textAlign: "center" }}>
          <Link
            to="/me/reservations"
            style={{
              color: "#6366f1",
              textDecoration: "none",
              fontWeight: 500,
              fontSize: 14,
            }}
          >
            Vezi rezervările mele →
          </Link>
        </div>
      </div>

      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes slideUp {
          from { transform: translateY(20px); opacity: 0; }
          to { transform: translateY(0); opacity: 1; }
        }
      `}</style>
    </div>
  );
}
