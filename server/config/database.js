const mysql = require('mysql2/promise');
require('dotenv').config();

console.log('\n🔧 Initializing MySQL Database Connection...');
console.log(`📍 Host: ${process.env.DB_HOST || 'localhost'}`);
console.log(`🔌 Port: ${process.env.DB_PORT || 3306}`);
console.log(`👤 User: ${process.env.DB_USER || 'root'}`);
console.log(`🗄️  Database: ${process.env.DB_NAME || 'password_manager'}`);

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'password_manager',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Test connection with detailed logging
pool.getConnection()
  .then(connection => {
    console.log('✅ MySQL Database connected successfully');
    console.log(`📊 Connection ID: ${connection.threadId}`);
    console.log(`⚙️  Connection limit: 10`);
    console.log(`⏱️  Connected at: ${new Date().toISOString()}\n`);
    connection.release();
  })
  .catch(err => {
    console.error('\n❌ CRITICAL: Error connecting to MySQL Database');
    console.error(`📛 Error Code: ${err.code}`);
    console.error(`📛 Error Message: ${err.message}`);
    console.error(`📚 Stack Trace:\n${err.stack}`);
    console.error('\n⚠️  Server may not function properly without database connection!\n');
  });

// Add error handler for pool
pool.on('error', (err) => {
  console.error('\n❌ MySQL Pool Error:');
  console.error(`📛 Error: ${err.message}`);
  console.error(`⏰ Time: ${new Date().toISOString()}\n`);
});

module.exports = pool;
