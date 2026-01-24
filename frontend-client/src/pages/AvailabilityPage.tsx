import { useEffect, useMemo, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import dayjs from "dayjs";
import { api } from "../api";

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
          boxShadow: "0 20px 40px rgba(0,0,0,0.2)",
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

export default function AvailabilityPage() {
  const { id } = useParams();
  const nav = useNavigate();
  const restaurantId = Number(id);

  const today = useMemo(() => dayjs().format("YYYY-MM-DD"), []);
  const [date, setDate] = useState(today);
  const [persons, setPersons] = useState(2);
  const [duration, setDuration] = useState(90);
  const [slots, setSlots] = useState<string[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState<{ text: string; isTableBooked?: boolean } | null>(null);

  async function load() {
    setErr(null);
    try {
      const res = await api.get(
        `/api/restaurants/${restaurantId}/availability?date=${date}&persons=${persons}&duration=${duration}`
      );
      setSlots(res.data);
    } catch (e: any) {
      setErr(e?.response?.data?.message ?? "Cannot load availability");
      setSlots([]);
    }
  }

  useEffect(() => {
    if (!Number.isFinite(restaurantId)) return;
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [restaurantId, date, persons, duration]);

  async function book(slot: string) {
    setErr(null);
    try {
      await api.post("/reservations", {
        restaurantId,
        startDt: slot,
        persons,
        durationMin: duration,
      });
      nav("/me/reservations");
    } catch (e: any) {
      let errorText = "Booking failed";
      if (e.response?.data?.message) {
        errorText = e.response.data.message;
      } else if (e.response?.data) {
        errorText = String(e.response.data);
      } else if (e.message) {
        errorText = e.message;
      }
      errorText = errorText.replace(/^\d+\s+\S+\s+/, "");
      const isTableBooked = errorText.includes("deja rezervată") || errorText.includes("already booked");
      setErrorMessage({ text: errorText, isTableBooked });
      setShowErrorModal(true);
    }
  }

  return (
    <div>
      <Modal
        isOpen={showErrorModal}
        onClose={() => {
          setShowErrorModal(false);
          setErrorMessage(null);
        }}
        onConfirm={() => {
          setShowErrorModal(false);
          setErrorMessage(null);
        }}
        title={errorMessage?.isTableBooked ? "Masa este deja rezervată" : "Eroare"}
        confirmText="Închide"
        isDestructive={true}
      >
        <div
          style={{
            display: "flex",
            alignItems: "flex-start",
            gap: 12,
            padding: "12px 16px",
            backgroundColor: "#fef2f2",
            borderRadius: 8,
          }}
        >
          <span style={{ fontSize: 24 }}>{errorMessage?.isTableBooked ? "⚠️" : "❌"}</span>
          <span style={{ color: errorMessage?.isTableBooked ? "#d97706" : "#dc2626", fontWeight: 500 }}>
            {errorMessage?.text}
          </span>
        </div>
        {errorMessage?.isTableBooked && (
          <div style={{ fontSize: 13, color: "#64748b", marginTop: 12 }}>
            <strong>Sfat:</strong> Încearcă să selectezi o altă oră sau o durată diferită.
          </div>
        )}
      </Modal>

      <h2>Disponibilitate (Restaurant #{restaurantId})</h2>

      <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
        <label>
          Date:{" "}
          <input value={date} onChange={(e) => setDate(e.target.value)} type="date" />
        </label>

        <label>
          Persons:{" "}
          <input
            value={persons}
            onChange={(e) => setPersons(Number(e.target.value))}
            type="number"
            min={1}
            max={20}
          />
        </label>

        <label>
          Duration:{" "}
          <select value={duration} onChange={(e) => setDuration(Number(e.target.value))}>
            <option value={60}>60</option>
            <option value={90}>90</option>
            <option value={120}>120</option>
            <option value={150}>150</option>
          </select>
        </label>

        <button onClick={load}>Refresh</button>
      </div>

      {err && <p style={{ color: "crimson" }}>{err}</p>}

      <div style={{ marginTop: 12, display: "grid", gap: 8 }}>
        {slots.map((s) => (
          <button key={s} onClick={() => book(s)} style={{ textAlign: "left" }}>
            Book {s}
          </button>
        ))}
        {slots.length === 0 && <p>No slots</p>}
      </div>
    </div>
  );
}
