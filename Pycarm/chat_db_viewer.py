import os
import csv
import tkinter as tk
from tkinter import ttk, messagebox, filedialog

import psycopg2
from psycopg2.extras import RealDictCursor


# =========================================================
# CONFIG (ia valorile EXACT ca în DbUtil.java)
# Env Vars:
#   CHAT_DB_HOST=localhost
#   CHAT_DB_PORT=5544
#   CHAT_DB_NAME=chatdb
#   CHAT_DB_USER=chatuser
#   CHAT_DB_PASS=chatpass
# =========================================================

def env(*keys, default=""):
    for k in keys:
        v = os.getenv(k)
        if v is not None and str(v).strip() != "":
            return str(v).strip()
    return default

DB_HOST = env("CHAT_DB_HOST", "DB_HOST", default="localhost")
DB_PORT = int(env("CHAT_DB_PORT", "DB_PORT", default="5544"))
DB_NAME = env("CHAT_DB_NAME", "DB_NAME", default="chatdb")
DB_USER = env("CHAT_DB_USER", "DB_USER", default="chatuser")
DB_PASS = env("CHAT_DB_PASS", "DB_PASSWORD", "DB_PASS", default="chatpass")

DB_CLIENT_ENCODING = env("DB_CLIENT_ENCODING", default="UTF8").upper()
DB_RAW_TEXT_ENCODING = env("DB_RAW_TEXT_ENCODING", default="").upper()

REFRESH_MS = 1200


def connect():
    os.environ["PGCLIENTENCODING"] = DB_CLIENT_ENCODING
    opts = f"-c client_encoding={DB_CLIENT_ENCODING}"
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        options=opts,
    )
    conn.set_client_encoding(DB_CLIENT_ENCODING)
    return conn


def fix_text_if_needed(s: str) -> str:
    if not isinstance(s, str) or not s or not DB_RAW_TEXT_ENCODING:
        return s
    try:
        return s.encode("latin1", errors="ignore").decode(DB_RAW_TEXT_ENCODING, errors="replace")
    except Exception:
        return s


# ======================= DARK THEME =======================

DARK = {
    "bg": "#0f1115",
    "panel": "#141821",
    "panel2": "#171c26",
    "text": "#e7eaf0",
    "muted": "#aab2c0",
    "accent": "#5aa7ff",
    "accent2": "#9a6bff",
    "danger": "#ff5a6a",
    "border": "#2a3140",
    "row_a": "#141821",
    "row_b": "#111520",
    "select": "#27324a",
    "header": "#1b2230",
}


def style_dark(root: tk.Tk):
    root.configure(bg=DARK["bg"])
    s = ttk.Style(root)

    # Use a theme that supports styling
    try:
        s.theme_use("clam")
    except Exception:
        pass

    base_font = ("Segoe UI", 10)
    s.configure(".", font=base_font, background=DARK["bg"], foreground=DARK["text"])

    s.configure("TFrame", background=DARK["bg"])
    s.configure("Card.TFrame", background=DARK["panel"])
    s.configure("Card2.TFrame", background=DARK["panel2"])

    s.configure("TLabel", background=DARK["bg"], foreground=DARK["text"])
    s.configure("Muted.TLabel", background=DARK["bg"], foreground=DARK["muted"])
    s.configure("Card.TLabel", background=DARK["panel"], foreground=DARK["text"])
    s.configure("Card2.TLabel", background=DARK["panel2"], foreground=DARK["text"])

    s.configure("TEntry",
                fieldbackground=DARK["panel2"],
                background=DARK["panel2"],
                foreground=DARK["text"],
                bordercolor=DARK["border"],
                lightcolor=DARK["border"],
                darkcolor=DARK["border"])
    s.configure("TCombobox",
                fieldbackground=DARK["panel2"],
                background=DARK["panel2"],
                foreground=DARK["text"],
                bordercolor=DARK["border"],
                lightcolor=DARK["border"],
                darkcolor=DARK["border"])
    s.map("TCombobox",
          fieldbackground=[("readonly", DARK["panel2"])],
          foreground=[("readonly", DARK["text"])],
          background=[("readonly", DARK["panel2"])])

    s.configure("TSpinbox",
                fieldbackground=DARK["panel2"],
                background=DARK["panel2"],
                foreground=DARK["text"])

    # Buttons
    s.configure("Accent.TButton",
                background=DARK["accent"],
                foreground="#0b0f16",
                bordercolor=DARK["accent"],
                focusthickness=1,
                focuscolor=DARK["accent"])
    s.map("Accent.TButton",
          background=[("active", "#7bbcff"), ("pressed", "#3b86da")])

    s.configure("Danger.TButton",
                background=DARK["danger"],
                foreground="#0b0f16",
                bordercolor=DARK["danger"])
    s.map("Danger.TButton",
          background=[("active", "#ff7c89"), ("pressed", "#e44254")])

    s.configure("TButton",
                background=DARK["header"],
                foreground=DARK["text"],
                bordercolor=DARK["border"])
    s.map("TButton",
          background=[("active", "#222b3e"), ("pressed", "#1b2230")])

    # Treeview
    s.configure("Treeview",
                background=DARK["panel"],
                fieldbackground=DARK["panel"],
                foreground=DARK["text"],
                bordercolor=DARK["border"],
                lightcolor=DARK["border"],
                darkcolor=DARK["border"],
                rowheight=26)
    s.configure("Treeview.Heading",
                background=DARK["header"],
                foreground=DARK["text"],
                relief="flat")
    s.map("Treeview",
          background=[("selected", DARK["select"])],
          foreground=[("selected", DARK["text"])])


# ======================= APP =======================

class ChatDBViewer(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Chat DB Viewer — Dark")
        self.geometry("1240x720")
        self.minsize(1020, 620)

        style_dark(self)

        self.conn = None
        self.cur = None

        self.filter_sender_var = tk.StringVar()
        self.filter_text_var = tk.StringVar()
        self.limit_var = tk.IntVar(value=200)

        # zi / interval
        self.day_mode_var = tk.StringVar(value="Toate")
        self.custom_from_var = tk.StringVar(value="")  # YYYY-MM-DD
        self.custom_to_var = tk.StringVar(value="")    # YYYY-MM-DD

        self.status_var = tk.StringVar(value="Neconectat")

        self._build_ui()
        self._connect()

        # prima încărcare (full)
        self.reload_full()

        self.after(REFRESH_MS, self._auto_refresh)

    # ---------------- UI ----------------

    def _build_ui(self):
        # Top bar (card)
        top_card = ttk.Frame(self, style="Card.TFrame", padding=12)
        top_card.pack(fill="x", padx=14, pady=(14, 10))

        header = ttk.Frame(top_card, style="Card.TFrame")
        header.pack(fill="x")

        title = ttk.Label(header, text="Chat DB Viewer", style="Card.TLabel",
                          font=("Segoe UI", 14, "bold"))
        title.pack(side="left")

        subtitle = ttk.Label(header, text="mesaje din tabelul: message  •  useri: app_user",
                             style="Card.TLabel", foreground=DARK["muted"])
        subtitle.pack(side="left", padx=(12, 0))

        # controls row
        controls = ttk.Frame(top_card, style="Card.TFrame")
        controls.pack(fill="x", pady=(12, 0))

        ttk.Label(controls, text="Sender", style="Card.TLabel").grid(row=0, column=0, sticky="w")
        ttk.Entry(controls, textvariable=self.filter_sender_var, width=18).grid(row=1, column=0, sticky="we", padx=(0, 10))

        ttk.Label(controls, text="Text", style="Card.TLabel").grid(row=0, column=1, sticky="w")
        ttk.Entry(controls, textvariable=self.filter_text_var, width=28).grid(row=1, column=1, sticky="we", padx=(0, 10))

        ttk.Label(controls, text="Limit", style="Card.TLabel").grid(row=0, column=2, sticky="w")
        ttk.Spinbox(controls, from_=10, to=5000, textvariable=self.limit_var, width=8).grid(row=1, column=2, sticky="w", padx=(0, 12))

        ttk.Label(controls, text="Zi", style="Card.TLabel").grid(row=0, column=3, sticky="w")
        day_box = ttk.Combobox(
            controls,
            textvariable=self.day_mode_var,
            values=["Azi", "Ieri", "Ultimele 7 zile", "Ultimele 30 zile", "Toate", "Custom"],
            state="readonly",
            width=16
        )
        day_box.grid(row=1, column=3, sticky="w", padx=(0, 10))
        day_box.bind("<<ComboboxSelected>>", lambda e: self._on_day_mode_changed())

        # custom range inputs
        self.custom_wrap = ttk.Frame(controls, style="Card.TFrame")
        self.custom_wrap.grid(row=1, column=4, sticky="w")

        ttk.Label(controls, text="(Custom: YYYY-MM-DD)", style="Card.TLabel",
                  foreground=DARK["muted"]).grid(row=0, column=4, sticky="w")

        ttk.Entry(self.custom_wrap, textvariable=self.custom_from_var, width=12).pack(side="left")
        ttk.Label(self.custom_wrap, text="→", style="Card.TLabel").pack(side="left", padx=6)
        ttk.Entry(self.custom_wrap, textvariable=self.custom_to_var, width=12).pack(side="left")

        # buttons
        btns = ttk.Frame(top_card, style="Card.TFrame")
        btns.pack(fill="x", pady=(12, 0))

        ttk.Button(btns, text="Refresh acum", style="Accent.TButton", command=self.reload_full).pack(side="left")
        ttk.Button(btns, text="Export CSV", command=self.export_csv).pack(side="left", padx=10)

        ttk.Button(btns, text="Clear mesaje (DB)", style="Danger.TButton", command=self.clear_db_dialog).pack(side="right")

        # Table card
        mid_card = ttk.Frame(self, style="Card2.TFrame", padding=(12, 10))
        mid_card.pack(fill="both", expand=True, padx=14, pady=(0, 10))

        self.tree = ttk.Treeview(
            mid_card,
            columns=("id", "time", "from", "to", "msg"),
            show="headings"
        )
        self.tree.heading("id", text="ID")
        self.tree.heading("time", text="Sent At")
        self.tree.heading("from", text="From")
        self.tree.heading("to", text="To")
        self.tree.heading("msg", text="Message")

        self.tree.column("id", width=70, anchor="center")
        self.tree.column("time", width=175, anchor="w")
        self.tree.column("from", width=170, anchor="w")
        self.tree.column("to", width=170, anchor="w")
        self.tree.column("msg", width=650, anchor="w")

        vsb = ttk.Scrollbar(mid_card, orient="vertical", command=self.tree.yview)
        hsb = ttk.Scrollbar(mid_card, orient="horizontal", command=self.tree.xview)
        self.tree.configure(yscrollcommand=vsb.set, xscrollcommand=hsb.set)

        self.tree.grid(row=0, column=0, sticky="nsew")
        vsb.grid(row=0, column=1, sticky="ns")
        hsb.grid(row=1, column=0, sticky="ew")

        mid_card.rowconfigure(0, weight=1)
        mid_card.columnconfigure(0, weight=1)

        # zebra rows
        self.tree.tag_configure("row_a", background=DARK["row_a"])
        self.tree.tag_configure("row_b", background=DARK["row_b"])

        # Bottom status
        bottom = ttk.Frame(self, padding=12)
        bottom.pack(fill="x")
        ttk.Label(bottom, textvariable=self.status_var, style="Muted.TLabel").pack(side="left")

        self._on_day_mode_changed(initial=True)

    def _on_day_mode_changed(self, initial=False):
        mode = self.day_mode_var.get().strip()
        show_custom = (mode == "Custom")
        if show_custom:
            self.custom_wrap.grid()
        else:
            self.custom_wrap.grid_remove()
        if not initial:
            self.reload_full()

    # ---------------- DB connect ----------------

    def _connect(self):
        try:
            self.conn = connect()
            self.cur = self.conn.cursor(cursor_factory=RealDictCursor)

            self.cur.execute("SHOW server_encoding;")
            server_enc = self.cur.fetchone()["server_encoding"]
            self.cur.execute("SHOW client_encoding;")
            client_enc = self.cur.fetchone()["client_encoding"]

            self.status_var.set(
                f"Conectat ✓ host={DB_HOST}:{DB_PORT} db={DB_NAME} user={DB_USER} | server={server_enc} client={client_enc}"
            )
        except Exception as e:
            messagebox.showerror("Eroare conectare", str(e))
            self.status_var.set(f"Neconectat | {e}")

    # ---------------- Query helpers ----------------

    def _date_filter_sql(self, where, params):
        """
        Adaugă filtrare după zi/interval în WHERE.
        """
        mode = self.day_mode_var.get().strip()

        if mode == "Toate":
            return

        if mode == "Azi":
            where.append("sent_at::date = CURRENT_DATE")
            return

        if mode == "Ieri":
            where.append("sent_at::date = (CURRENT_DATE - INTERVAL '1 day')::date")
            return

        if mode == "Ultimele 7 zile":
            where.append("sent_at >= (CURRENT_DATE - INTERVAL '7 days')")
            return

        if mode == "Ultimele 30 zile":
            where.append("sent_at >= (CURRENT_DATE - INTERVAL '30 days')")
            return

        # Custom: YYYY-MM-DD -> YYYY-MM-DD
        if mode == "Custom":
            d1 = self.custom_from_var.get().strip()
            d2 = self.custom_to_var.get().strip()

            if d1 and d2:
                where.append("sent_at::date BETWEEN %s::date AND %s::date")
                params.extend([d1, d2])
            elif d1:
                where.append("sent_at::date >= %s::date")
                params.append(d1)
            elif d2:
                where.append("sent_at::date <= %s::date")
                params.append(d2)
            # dacă sunt goale, nu filtrăm
            return

    def _build_where(self, include_incremental: bool):
        where = []
        params = []

        sender = self.filter_sender_var.get().strip()
        if sender:
            where.append("LOWER(sender_username) LIKE LOWER(%s)")
            params.append(f"%{sender}%")

        text = self.filter_text_var.get().strip()
        if text:
            where.append("LOWER(content) LIKE LOWER(%s)")
            params.append(f"%{text}%")

        self._date_filter_sql(where, params)

        # incremental: doar după id
        if include_incremental:
            last_id = self._get_last_tree_id()
            if last_id is not None:
                where.append("id > %s")
                params.append(last_id)

        where_sql = (" WHERE " + " AND ".join(where)) if where else ""
        return where_sql, params

    def _get_last_tree_id(self):
        kids = self.tree.get_children()
        if not kids:
            return None
        try:
            last_vals = self.tree.item(kids[-1], "values")
            return int(last_vals[0])
        except Exception:
            return None

    def _clear_tree(self):
        for item in self.tree.get_children():
            self.tree.delete(item)

    # ---------------- Refresh / Load ----------------

    def reload_full(self):
        """
        Reîncarcă complet lista (util când schimbi zi/filtru).
        """
        if not self.cur:
            return

        try:
            self._clear_tree()

            where_sql, params = self._build_where(include_incremental=False)
            limit = int(self.limit_var.get())

            sql = f"""
                SELECT id, sent_at, sender_username, receiver_username, content
                FROM message
                {where_sql}
                ORDER BY id ASC
                LIMIT %s
            """
            params.append(limit)

            self.cur.execute(sql, tuple(params))
            rows = self.cur.fetchall()

            self._insert_rows(rows)

            self.status_var.set(self.status_var.get().split(" | ")[0] + f" | încărcate: {len(rows)}")
        except Exception as e:
            self.status_var.set(f"Eroare reload: {e}")

    def refresh_incremental(self):
        """
        Auto-refresh: adaugă doar rândurile noi (id mai mare).
        Nu schimbă lista când ai filtre/zi (se respectă).
        """
        if not self.cur:
            return

        try:
            where_sql, params = self._build_where(include_incremental=True)
            limit = int(self.limit_var.get())

            sql = f"""
                SELECT id, sent_at, sender_username, receiver_username, content
                FROM message
                {where_sql}
                ORDER BY id ASC
                LIMIT %s
            """
            params.append(limit)

            self.cur.execute(sql, tuple(params))
            rows = self.cur.fetchall()
            if not rows:
                return

            self._insert_rows(rows)

        except Exception as e:
            self.status_var.set(f"Eroare refresh: {e}")

    def _insert_rows(self, rows):
        if not rows:
            return

        start_index = len(self.tree.get_children())
        for i, r in enumerate(rows):
            rid = r["id"]
            sent_at = str(r["sent_at"]) if r["sent_at"] is not None else ""
            sender_u = fix_text_if_needed(r["sender_username"] or "")
            recv_u = fix_text_if_needed(r["receiver_username"] or "")
            content = fix_text_if_needed(r["content"] or "")

            tag = "row_a" if ((start_index + i) % 2 == 0) else "row_b"
            self.tree.insert("", "end", values=(rid, sent_at, sender_u, recv_u, content), tags=(tag,))

        kids = self.tree.get_children()
        if kids:
            self.tree.see(kids[-1])

    def _auto_refresh(self):
        self.refresh_incremental()
        self.after(REFRESH_MS, self._auto_refresh)

    # ---------------- Export ----------------

    def export_csv(self):
        try:
            path = filedialog.asksaveasfilename(
                defaultextension=".csv",
                filetypes=[("CSV", "*.csv")],
                title="Salvează export CSV"
            )
            if not path:
                return

            with open(path, "w", newline="", encoding="utf-8") as f:
                w = csv.writer(f)
                w.writerow(["id", "sent_at", "sender_username", "receiver_username", "content"])
                for item in self.tree.get_children():
                    w.writerow(self.tree.item(item, "values"))

            messagebox.showinfo("OK", f"Exportat în:\n{path}")
        except Exception as e:
            messagebox.showerror("Eroare export", str(e))

    # ---------------- Clear DB ----------------

    def clear_db_dialog(self):
        """
        Clear mesaje din DB cu confirmare.
        Poți șterge:
          - toate mesajele
          - doar mesajele pentru ziua/intervalul selectat
        """
        if not self.cur:
            return

        mode = self.day_mode_var.get().strip()
        scope_txt = "TOATE mesajele" if mode == "Toate" else f"mesajele din filtrul de zi ({mode})"

        msg = (
            f"ATENȚIE!\n\nVrei să ștergi {scope_txt} din baza de date?\n"
            f"Această acțiune NU poate fi anulată.\n\n"
            f"Scrie: DELETE ca să confirmi."
        )

        answer = simple_input(self, "Confirmare ștergere", msg)
        if answer != "DELETE":
            messagebox.showinfo("Anulat", "Ștergerea a fost anulată.")
            return

        try:
            where = []
            params = []
            # aplicăm doar filtrul de zi, NU și sender/text (ca să fie clar: zi = scope)
            # dacă vrei și sender/text, spune-mi și îl fac.
            self._date_filter_sql(where, params)
            where_sql = (" WHERE " + " AND ".join(where)) if where else ""

            sql = "DELETE FROM message" + where_sql
            self.cur.execute(sql, tuple(params))
            self.conn.commit()

            # reîncarcă UI
            self.reload_full()
            messagebox.showinfo("OK", "Mesajele au fost șterse din DB.")
        except Exception as e:
            try:
                self.conn.rollback()
            except Exception:
                pass
            messagebox.showerror("Eroare", f"Nu am putut șterge mesajele:\n{e}")


def simple_input(root, title, text):
    """
    Mini dialog pentru input (confirmare DELETE).
    """
    win = tk.Toplevel(root)
    win.title(title)
    win.configure(bg=DARK["bg"])
    win.resizable(False, False)
    win.transient(root)
    win.grab_set()

    frm = ttk.Frame(win, style="Card.TFrame", padding=12)
    frm.pack(fill="both", expand=True, padx=12, pady=12)

    lbl = ttk.Label(frm, text=text, style="Card.TLabel", justify="left")
    lbl.pack(anchor="w")

    entry = ttk.Entry(frm, width=30)
    entry.pack(fill="x", pady=(10, 10))
    entry.focus_set()

    out = {"val": None}

    btns = ttk.Frame(frm, style="Card.TFrame")
    btns.pack(fill="x")

    def ok():
        out["val"] = entry.get().strip()
        win.destroy()

    def cancel():
        out["val"] = None
        win.destroy()

    ttk.Button(btns, text="Confirm", style="Danger.TButton", command=ok).pack(side="right")
    ttk.Button(btns, text="Anulează", command=cancel).pack(side="right", padx=10)

    win.bind("<Return>", lambda e: ok())
    win.bind("<Escape>", lambda e: cancel())

    root.wait_window(win)
    return out["val"]


if __name__ == "__main__":
    ChatDBViewer().mainloop()
