const API = url => fetch(url, {credentials: 'include'}).then(r => r.json());

async function checkLogin(role = null) {
    const r = await API('auth.php?action=session');
    if (!r.user || (role && r.user.role !== role)) { 
        location.href = 'index.html'; 
        return; 
    }
    const el = document.getElementById('userInfo');
    if (el) el.innerHTML = `${r.user.nickname} (${r.user.role})`;
    return r.user;
}

function logout() {
    fetch('auth.php?action=logout', {credentials: 'include'})
    .then(() => {
        localStorage.clear();
        location.href = 'index.html';
    });
}