# Turcan Task Manager (Trello Clone)

Un manager de task-uri full-stack inspirat de Trello, cu funcționalități moderne, real-time și design adaptiv.

## Features
- Autentificare (register, login, logout)
- Boards, lists, cards CRUD
- Drag & drop pentru liste și carduri
- Real-time updates cu Socket.io
- Profile dropdown: Edit Account, Dark/Light Theme, Logout
- Editare profil
- Dark mode complet (toate paginile și componentele)
- Card borders colorate (10 culori)
- List color picker (8 opțiuni, paletă de culori)
- Management membri board
- Board settings (edit, delete)

## Tehnologii folosite și rolul lor

### Frontend
- **Next.js 15**: Framework React pentru SSR/SSG, routing modern și performanță crescută.
- **React 19**: Bibliotecă pentru UI component-based, interactivitate și reactivitate.
- **TypeScript**: Tipare statice pentru siguranță și scalabilitate.
- **TailwindCSS**: Utilizat pentru design rapid, responsiv și dark mode (prin clase `dark:`).
- **@hello-pangea/dnd**: Drag & drop performant pentru liste și carduri.

### Backend
- **Node.js**: Runtime JavaScript pe server, rapid și scalabil.
- **Express.js**: Framework pentru API REST, routing și middlewares.
- **Socket.io**: Comunicare real-time (evenimente: list/card create, update, board rooms etc).
- **MySQL 8+**: Bază de date relațională, stochează utilizatori, boards, lists, cards, etc.
- **mysql2**: Driver performant pentru conectarea Node.js la MySQL.
- **JWT**: Autentificare securizată cu token-uri.
- **bcryptjs**: Hashing parole pentru securitate.

### Alte tehnologii
- **Express-validator**: Validare date la API.
- **Multer**: Upload fișiere (pentru extensii viitoare).
- **TailwindCSS dark mode**: Trecerea între light/dark se face cu clasa `dark` pe `document.documentElement`, persistată în localStorage.

## Cum funcționează aplicația
- **Autentificare:** Utilizatorii se pot înregistra/loga. Parolele sunt hash-uite cu bcryptjs, autentificarea se face cu JWT.
- **Boards/Lists/Cards:** CRUD complet, datele sunt stocate în MySQL. Fiecare board are liste, fiecare listă are carduri.
- **Drag & Drop:** Implementat cu @hello-pangea/dnd, mută carduri/liste cu update instant în UI și backend.
- **Real-time:** Socket.io folosește rooms pentru fiecare board, astfel încât acțiunile (creare, mutare, editare) sunt propagate instant la toți membrii boardului.
- **Dark/Light Theme:** Toggle din dropdown profil, persistă preferința în localStorage, schimbă clasa `dark` pe root.
- **Profile Dropdown:** Permite editarea profilului, schimbarea temei și logout.
- **List Color Picker:** Fiecare listă are o paletă de culori, culoarea se salvează în DB și se reflectă instant în UI.

## Instalare
### 1. Backend
```bash
cd server
npm install
npm run migrate:list-color # rulează migrarea pentru coloana de culoare la liste
npm run dev
```

### 2. Frontend
```bash
cd client
npm install
npm run dev
```

## Configurare DB
Setează variabilele de mediu în `server/.env`:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=parola_ta
DB_NAME=turcan
JWT_SECRET=secretul_tau
```

## Utilizare
1. Creează cont sau loghează-te
2. Creează board-uri, liste și carduri
3. Folosește drag & drop pentru organizare
4. Schimbă tema (dark/light) din dropdown profil
5. Editează profilul din dropdown
6. Schimbă culoarea listelor cu paleta de culori

## Screenshots
> Adaugă imagini cu aplicația aici pentru o prezentare vizuală

## Contribuie
Pull requests și sugestii sunt binevenite!

## Licență
MIT
