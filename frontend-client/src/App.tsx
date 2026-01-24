import React from "react";
import { Navigate, Route, Routes } from "react-router-dom";
import Login from "./pages/Login";
import Restaurants from "./pages/Restaurants";
import RestaurantBooking from "./pages/RestaurantBooking";
import MyReservations from "./pages/MyReservations";
import AdminPage from "./pages/AdminPage";
import { getToken } from "./lib/auth";

function RequireAuth({ children }: { children: React.JSX.Element }) {
  const token = getToken();
  if (!token) return <Navigate to="/login" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />

      <Route
        path="/restaurants"
        element={
          <RequireAuth>
            <Restaurants />
          </RequireAuth>
        }
      />
      <Route
        path="/restaurants/:id"
        element={
          <RequireAuth>
            <RestaurantBooking />
          </RequireAuth>
        }
      />
      <Route
        path="/me/reservations"
        element={
          <RequireAuth>
            <MyReservations />
          </RequireAuth>
        }
      />
      <Route
        path="/admin"
        element={
          <RequireAuth>
            <AdminPage />
          </RequireAuth>
        }
      />

      <Route path="*" element={<Navigate to="/restaurants" replace />} />
    </Routes>
  );
}
