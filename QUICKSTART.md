# 🚀 Quick Start Guide - Chess App

## Pornire Rapidă (2 minute)

### 1. Server (Terminal 1)

```bash
cd acs_proiect
pip install -r requirements.txt
python main.py
```

✅ Server pornit pe `http://localhost:8000`

### 2. Client (Terminal 2)

```bash
cd client
npm install
npm run dev
```

✅ Client pornit pe `http://localhost:5173`

### 3. Test Joc Multiplayer (2 browsere)

**Browser 1 (Chrome):**
```
1. http://localhost:5173
2. Register: user1 / password1
3. Login
4. Creează joc → Alb
```

**Browser 2 (Firefox sau Incognito):**
```
1. http://localhost:5173
2. Register: user2 / password2
3. Login
4. Caută joc → Join
```

✅ Ambele browsere vor vedea tabla și vor putea juca!

## 📋 Verificare Rapidă

| Funcționalitate | Cum să testezi |
|----------------|----------------|
| **Meniu centrat** | Login → Vezi dacă cardul e centrat perfect |
| **Butoane noi** | Verifică ordinea: Profile, Game History, Creează, Caută |
| **Profile offline** | Vizitează Profile → Oprește server Python → Reload → Funcționează? |
| **Game History offline** | Vizitează Game History → Oprește server → Reload → Funcționează? |
| **Joc funcțional** | 2 browsere, creează + join, fă mutări |
| **Click Chess App** | În timpul jocului, click pe "♟️ Chess App" → Apare confirmare? |
| **Resign** | În joc, click "Abandonează & Ieși" → Adversarul vede mesaj? |

## 🔍 Debug Rapid

**Joc blocat "Se încarcă..."?**
```javascript
// În console browser:
localStorage.getItem("player_id")  // Trebuie să returneze un număr
```

**Server nu răspunde?**
```bash
curl http://localhost:8000/lobby/waiting
# Trebuie să returneze lista de jocuri (sau [])
```

**WebSocket nu merge?**
```
F12 → Network → WS → Vezi conexiunea?
```

## ✅ Checklist Implementare

- [x] Meniu centrat perfect (orizontal + vertical)
- [x] Ordine butoane: Profile, Game History, Creează, Caută
- [x] Profile funcționează offline
- [x] Game History funcționează offline
- [x] Bug "Se încarcă..." reparat
- [x] Jocul pornește când ambii jucători se conectează
- [x] Click pe "Chess App" cu confirmare în joc
- [x] Resign/Abandon funcțional
- [x] Tema dark păstrată
- [x] Responsive pe toate dispozitivele

## 📚 Link-uri Utile

- [README Complet](./README.md)
- [Ghid Implementare Detaliat](./IMPLEMENTATION_GUIDE.md)
- API Docs (cu server pornit): http://localhost:8000/docs

---

**Gata! Ai totul implementat și funcțional! 🎉**
