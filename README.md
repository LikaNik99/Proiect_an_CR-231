# 🔐 Password Manager - Aplicație Client-Server

Aplicație completă de management parole cu arhitectură client-server, bază de date MySQL și containerizare Docker.

## 📋 Cuprins
- [Caracteristici](#caracteristici)
- [Tehnologii Utilizate](#tehnologii-utilizate)
- [Arhitectură](#arhitectură)
- [Instalare și Rulare](#instalare-și-rulare)
- [API Documentation](#api-documentation)
- [Securitate](#securitate)
- [Capturi de Ecran](#capturi-de-ecran)

## ✨ Caracteristici

### Partea de Client (Frontend)
- ✅ Autentificare și înregistrare utilizatori
- ✅ Dashboard intuitiv pentru gestionarea parolelor
- ✅ Adăugare, editare, vizualizare și ștergere parole
- ✅ Generator de parole securizate
- ✅ Căutare și filtrare după categorie
- ✅ Copiere rapidă în clipboard
- ✅ Marcare parole ca favorite
- ✅ Interfață modernă și responsive

### Partea de Server (Backend)
- ✅ API RESTful cu Express.js
- ✅ Autentificare JWT (JSON Web Tokens)
- ✅ Criptare end-to-end a parolelor (AES-256-CBC)
- ✅ Hash-uire parole utilizatori cu bcrypt
- ✅ Validare date cu express-validator
- ✅ Rate limiting pentru securitate
- ✅ CORS și Helmet pentru protecție

### Bază de Date
- ✅ MySQL 8.0
- ✅ Schema bine definită cu relații
- ✅ Indexare pentru performanță
- ✅ Cascade delete pentru integritate

### DevOps
- ✅ Containerizare completă cu Docker
- ✅ Docker Compose pentru orchestrare
- ✅ Volume persistente pentru date
- ✅ Health checks pentru servicii

## 🛠 Tehnologii Utilizate

### Backend
- **Node.js** - Runtime JavaScript
- **Express.js** - Framework web
- **MySQL** - Bază de date relațională
- **JWT** - Autentificare
- **bcryptjs** - Hash-uire parole
- **crypto** - Criptare AES-256
- **helmet** - Securitate HTTP headers
- **cors** - Cross-Origin Resource Sharing
- **express-rate-limit** - Limitare cereri

### Frontend
- **React** - Bibliotecă UI
- **React Router** - Routing
- **Axios** - HTTP client
- **React Icons** - Iconițe

### Database
- **MySQL 8.0** - Bază de date

### DevOps
- **Docker** - Containerizare
- **Docker Compose** - Orchestrare
- **Nginx** - Server web pentru client

## 🏗 Arhitectură

```
├── client/                 # Aplicație React
│   ├── public/
│   ├── src/
│   │   ├── context/       # Context pentru autentificare
│   │   ├── pages/         # Pagini (Login, Register, Dashboard)
│   │   ├── services/      # API calls
│   │   ├── App.js
│   │   └── index.js
│   ├── Dockerfile
│   └── package.json
│
├── server/                # Server Node.js
│   ├── config/           # Configurări (database)
│   ├── middleware/       # Middleware (auth)
│   ├── routes/           # Rute API (auth, passwords)
│   ├── utils/            # Utilități (encryption)
│   ├── init.sql          # Schema MySQL
│   ├── server.js         # Punct de intrare
│   ├── Dockerfile
│   └── package.json
│
├── docker-compose.yml    # Orchestrare servicii
├── .env.example          # Exemplu variabile mediu
└── README.md            # Documentație
```

## 🚀 Instalare și Rulare

### Prerequisite
- Docker Desktop instalat
- Git (opțional)

### Pași de Instalare

#### 1. Clonează sau descarcă proiectul
```bash
cd c:\Users\skrpt\Desktop\UTM\ACS\proiect_de_an
```

#### 2. Configurare variabile de mediu
Creează fișierul `.env` în directorul root (sau copiază `.env.example`):
```bash
copy .env.example .env
```

**IMPORTANT:** Schimbă valorile în producție:
- `JWT_SECRET` - Cheie secretă pentru JWT
- `ENCRYPTION_KEY` - Trebuie să fie exact 32 caractere
- `MYSQL_ROOT_PASSWORD` - Parola root MySQL
- `DB_PASSWORD` - Parola utilizatorului MySQL

#### 3. Rulare cu Docker Compose

**Pornire aplicație:**
```bash
docker-compose up -d
```

**Verificare status:**
```bash
docker-compose ps
```

**Vizualizare logs:**
```bash
docker-compose logs -f
```

**Oprire aplicație:**
```bash
docker-compose down
```

**Oprire și ștergere date:**
```bash
docker-compose down -v
```

#### 4. Acces Aplicație

- **Client (Frontend):** http://localhost:3000
- **Server (API):** http://localhost:5000
- **MySQL:** localhost:3306

### Rulare în Modul Dezvoltare (fără Docker)

#### Server
```bash
cd server
npm install
npm run dev
```

#### Client
```bash
cd client
npm install
npm start
```

#### MySQL
Asigură-te că ai MySQL instalat local și rulează scriptul `init.sql`:
```bash
mysql -u root -p < server/init.sql
```

## 📡 API Documentation

### Autentificare

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securepass123"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "johndoe",
  "password": "securepass123"
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer <token>
```

### Passwords

#### Get All Passwords
```http
GET /api/passwords
Authorization: Bearer <token>
```

#### Get Single Password (decrypted)
```http
GET /api/passwords/:id
Authorization: Bearer <token>
```

#### Create Password
```http
POST /api/passwords
Authorization: Bearer <token>
Content-Type: application/json

{
  "website": "facebook.com",
  "username": "myusername",
  "email": "my@email.com",
  "password": "mypassword123",
  "category": "Social Media",
  "notes": "Main account",
  "favorite": false
}
```

#### Update Password
```http
PUT /api/passwords/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "website": "facebook.com",
  "password": "newpassword123"
}
```

#### Delete Password
```http
DELETE /api/passwords/:id
Authorization: Bearer <token>
```

#### Generate Random Password
```http
POST /api/passwords/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "length": 16
}
```

## 🔒 Securitate

### Măsuri de Securitate Implementate

1. **Criptare Parole**
   - AES-256-CBC pentru criptarea parolelor salvate
   - Fiecare parolă are propriul IV (Initialization Vector)
   - Cheie de criptare separată pentru mediu

2. **Autentificare**
   - JWT tokens cu expirare (24h)
   - Hash-uire parole utilizatori cu bcrypt (10 rounds)
   - Verificare token la fiecare cerere protejată

3. **Validare Input**
   - Express-validator pentru validare date
   - Sanitizare input utilizator
   - Verificare tipuri de date

4. **Protecție HTTP**
   - Helmet.js pentru headers securizate
   - CORS configurat corect
   - Rate limiting (100 cereri/15 minute)

5. **Bază de Date**
   - Prepared statements (previne SQL injection)
   - Restricții Foreign Key
   - Indexare pentru performanță

### Best Practices

- ❌ **NU** folosi parolele din `.env.example` în producție
- ✅ Schimbă toate secretele înainte de deployment
- ✅ Folosește HTTPS în producție
- ✅ Backup regulat la baza de date
- ✅ Monitorizare logs pentru activități suspecte

## 🗄 Schema Bazei de Date

### Tabela `users`
```sql
- id (PK)
- username (UNIQUE)
- email (UNIQUE)
- password_hash
- created_at
- updated_at
```

### Tabela `passwords`
```sql
- id (PK)
- user_id (FK -> users.id)
- website
- username
- email
- encrypted_password
- iv (Initialization Vector)
- notes
- category
- favorite
- created_at
- updated_at
```

### Tabela `password_history` (opțional)
```sql
- id (PK)
- password_id (FK -> passwords.id)
- encrypted_password
- iv
- changed_at
```

### Tabela `sessions` (opțional)
```sql
- id (PK)
- user_id (FK -> users.id)
- token
- expires_at
- created_at
```

## 🐛 Debugging

### Verificare stare containere
```bash
docker-compose ps
```

### Verificare logs
```bash
# Toate serviciile
docker-compose logs -f

# Doar server
docker-compose logs -f server

# Doar MySQL
docker-compose logs -f mysql
```

### Conectare la MySQL
```bash
docker-compose exec mysql mysql -u appuser -p password_manager
# Parola: appuser_password_123
```

### Restart servicii
```bash
# Restart toate
docker-compose restart

# Restart doar server
docker-compose restart server
```

### Rebuild imagini
```bash
docker-compose up -d --build
```

## 📝 Funcționalități Viitoare

- [ ] Generare rapoarte de securitate
- [ ] Partajare parole între utilizatori
- [ ] Autentificare în doi pași (2FA)
- [ ] Import/Export parole (CSV, JSON)
- [ ] Istoricul parolelor
- [ ] Notificări expirare parole
- [ ] Aplicație mobile
- [ ] Extensie browser
- [ ] Dark mode

## 👨‍💻 Dezvoltare

### Structură Cod

- **Server:** Arhitectură MVC simplificată
- **Client:** Component-based architecture cu React
- **Database:** Schema normalizată

### Adăugare Funcționalități Noi

1. Creează rute noi în `server/routes/`
2. Adaugă endpoint-uri în `client/src/services/api.js`
3. Creează componente noi în `client/src/pages/`
4. Actualizează routing în `client/src/App.js`

## 📄 Licență

Acest proiect este creat pentru scopuri educaționale.

## 🤝 Contribuții

Contribuțiile sunt binevenite! Te rog să deschizi un issue sau pull request.

## 📧 Contact

Pentru întrebări sau suport, deschide un issue pe repository.

---

**Made with ❤️ for ACS UTM**
