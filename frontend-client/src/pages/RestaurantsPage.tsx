import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api";

type Restaurant = { id: number; name: string };

export default function RestaurantsPage() {
  const [items, setItems] = useState<Restaurant[]>([]);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const res = await api.get("/api/restaurants");
        setItems(res.data);
      } catch (e: any) {
        setErr(e?.response?.data?.message ?? "Cannot load restaurants");
      }
    })();
  }, []);

  return (
    <div>
      <h2>Restaurante</h2>
      {err && <p style={{ color: "crimson" }}>{err}</p>}
      <ul>
        {items.map((r) => (
          <li key={r.id}>
            {r.name}{" "}
            <Link to={`/restaurants/${r.id}/availability`}>Vezi disponibilitate</Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
