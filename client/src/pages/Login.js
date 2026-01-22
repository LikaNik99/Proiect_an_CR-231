import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './Auth.css';

const Login = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const result = await login(username, password);
    
    if (result.success) {
      navigate('/dashboard');
    } else {
      setError(result.error);
    }
    
    setLoading(false);
  };

  return (
    <div className="auth-container">
      <div className="auth-box">
        <h1>🔐 Password Manager</h1>
        <h2>Autentificare</h2>
        
        {error && <div className="error-message">{error}</div>}
        
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Username sau Email</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              placeholder="Introdu username sau email"
            />
          </div>

          <div className="form-group">
            <label>Parolă</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="Introdu parola"
            />
          </div>

          <button type="submit" className="btn-primary" disabled={loading}>
            {loading ? 'Se autentifică...' : 'Autentificare'}
          </button>
        </form>

        <p className="auth-link">
          Nu ai cont? <Link to="/register">Înregistrează-te aici</Link>
        </p>
      </div>
    </div>
  );
};

export default Login;
