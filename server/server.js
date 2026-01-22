const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// CORS - Allow all origins for local network access
const allowedOrigins = [
  'http://localhost:3000',
  process.env.CLIENT_URL
].filter(Boolean);

// Apply CORS early so every response (including errors/limits) gets headers
app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(null, true); // Allow all for development
    }
  },
  credentials: true
}));

// Explicitly handle preflight for all routes
app.options('*', cors());

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`\n[${timestamp}] ${req.method} ${req.url}`);
  console.log(`📍 Origin: ${req.headers.origin || 'No origin'}`);
  console.log(`🔑 Auth: ${req.headers.authorization ? 'Token present' : 'No token'}`);
  if (Object.keys(req.body).length > 0) {
    const sanitizedBody = { ...req.body };
    if (sanitizedBody.password) sanitizedBody.password = '***';
    console.log(`📦 Body:`, sanitizedBody);
  }
  
  // Log response
  const originalSend = res.send;
  res.send = function(data) {
    console.log(`✅ Response: ${res.statusCode}`);
    originalSend.call(this, data);
  };
  
  next();
});

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/passwords', require('./routes/passwords'));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Password Manager Server is running' });
});

// Root route
app.get('/', (req, res) => {
  res.json({ 
    message: 'Password Manager API',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      passwords: '/api/passwords',
      health: '/health'
    }
  });
});

// Error handler
app.use((err, req, res, next) => {
  const timestamp = new Date().toISOString();
  console.error(`\n❌ [${timestamp}] ERROR on ${req.method} ${req.url}`);
  console.error(`📛 Error Message: ${err.message}`);
  console.error(`📚 Stack Trace:\n${err.stack}`);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  const timestamp = new Date().toISOString();
  console.warn(`\n⚠️  [${timestamp}] 404 NOT FOUND: ${req.method} ${req.url}`);
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║          🔐 PASSWORD MANAGER SERVER STARTED 🔐           ║');
  console.log('╚════════════════════════════════════════════════════════════╝\n');
  console.log(`🚀 Server Status: RUNNING`);
  console.log(`⏰ Started at: ${new Date().toISOString()}`);
  console.log(`🔌 Port: ${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`\n📡 API Endpoints:`);
  console.log(`   - Local:   http://localhost:${PORT}`);
  console.log(`   - Network: http://0.0.0.0:${PORT}`);
  console.log(`\n🛣️  Available Routes:`);
  console.log(`   - POST /api/auth/register   → Register new user`);
  console.log(`   - POST /api/auth/login      → User login`);
  console.log(`   - GET  /api/passwords       → Get all passwords`);
  console.log(`   - POST /api/passwords       → Create password`);
  console.log(`   - PUT  /api/passwords/:id   → Update password`);
  console.log(`   - DELETE /api/passwords/:id → Delete password`);
  console.log(`   - GET  /health              → Health check`);
  console.log(`\n📱 Mobile Access: Use your computer's local IP on port ${PORT}`);
  console.log(`\n✅ Ready to accept connections...\n`);
  console.log('═══════════════════════════════════════════════════════════════\n');
});

module.exports = app;
