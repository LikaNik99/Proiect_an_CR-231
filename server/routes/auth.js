const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const { generateToken, auth } = require('../middleware/auth');

/**
 * @route   POST /api/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', [
  body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req, res) => {
  try {
    console.log('\n🔵 [REGISTER] Attempt started');
    
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ [REGISTER] Validation failed:', errors.array());
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, email, password } = req.body;
    console.log(`📝 [REGISTER] Username: ${username}, Email: ${email}`);
    console.log(`🔐 [REGISTER] Password length: ${password.length} characters`);

    // Check if user already exists
    console.log('🔍 [REGISTER] Checking for existing user...');
    const [existingUsers] = await db.query(
      'SELECT * FROM users WHERE username = ? OR email = ?',
      [username, email]
    );

    if (existingUsers.length > 0) {
      console.log('⚠️  [REGISTER] User already exists');
      return res.status(400).json({ error: 'Username or email already exists' });
    }
    console.log('✓ [REGISTER] No existing user found');

    // Hash password
    console.log('🔒 [REGISTER] Hashing password...');
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);
    console.log('✓ [REGISTER] Password hashed successfully');

    // Insert user
    console.log('💾 [REGISTER] Inserting user into database...');
    const [result] = await db.query(
      'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
      [username, email, passwordHash]
    );
    console.log(`✓ [REGISTER] User inserted with ID: ${result.insertId}`);

    // Generate token
    console.log('🎫 [REGISTER] Generating JWT token...');
    const token = generateToken({ 
      id: result.insertId, 
      username, 
      email 
    });
    console.log('✓ [REGISTER] Token generated successfully');

    console.log(`✅ [REGISTER] SUCCESS - User ${username} registered with ID ${result.insertId}\n`);
    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: result.insertId,
        username,
        email
      }
    });

  } catch (error) {
    console.error('\n❌ [REGISTER] FAILED - Error:', error.message);
    console.error('📚 [REGISTER] Stack:', error.stack);
    res.status(500).json({ error: 'Server error during registration' });
  }
});

/**
 * @route   POST /api/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', [
  body('username').notEmpty().withMessage('Username or email is required'),
  body('password').notEmpty().withMessage('Password is required')
], async (req, res) => {
  try {
    console.log('\n🔵 [LOGIN] Attempt started');
    
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ [LOGIN] Validation failed:', errors.array());
      return res.status(400).json({ errors: errors.array() });
    }

    const { username, password } = req.body;
    console.log(`📝 [LOGIN] Attempting login for: ${username}`);
    console.log(`🔐 [LOGIN] Password length: ${password.length} characters`);

    // Find user (allow login with username or email)
    console.log('🔍 [LOGIN] Searching for user in database...');
    const [users] = await db.query(
      'SELECT * FROM users WHERE username = ? OR email = ?',
      [username, username]
    );

    if (users.length === 0) {
      console.log('⚠️  [LOGIN] User not found');
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = users[0];
    console.log(`✓ [LOGIN] User found - ID: ${user.id}, Username: ${user.username}`);

    // Verify password
    console.log('🔐 [LOGIN] Verifying password...');
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      console.log('⚠️  [LOGIN] Password mismatch');
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    console.log('✓ [LOGIN] Password verified successfully');

    // Generate token
    console.log('🎫 [LOGIN] Generating JWT token...');
    const token = generateToken({ 
      id: user.id, 
      username: user.username, 
      email: user.email 
    });
    console.log('✓ [LOGIN] Token generated successfully');

    console.log(`✅ [LOGIN] SUCCESS - User ${user.username} (ID: ${user.id}) logged in\n`);
    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email
      }
    });

  } catch (error) {
    console.error('\n❌ [LOGIN] FAILED - Error:', error.message);
    console.error('📚 [LOGIN] Stack:', error.stack);
    res.status(500).json({ error: 'Server error during login' });
  }
});

/**
 * @route   GET /api/auth/me
 * @desc    Get current user
 * @access  Private
 */
router.get('/me', require('../middleware/auth').authenticateToken, async (req, res) => {
  try {
    const [users] = await db.query(
      'SELECT id, username, email, created_at FROM users WHERE id = ?',
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: users[0] });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * @route   POST /api/auth/verify-password
 * @desc    Verify master password
 * @access  Private
 */
router.post('/verify-password', [
  require('../middleware/auth').authenticateToken,
  body('password').notEmpty().withMessage('Password is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { password } = req.body;

    // Get user's password hash
    const [users] = await db.query(
      'SELECT password_hash FROM users WHERE id = ?',
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Verify password
    const isMatch = await bcrypt.compare(password, users[0].password_hash);
    
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid password', valid: false });
    }

    res.json({ 
      message: 'Password verified successfully',
      valid: true 
    });

  } catch (error) {
    console.error('Verify password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Update user profile (email and/or password)
router.put('/profile', auth, [
  body('email').optional().isEmail().withMessage('Valid email is required'),
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').optional().isLength({ min: 6 }).withMessage('New password must be at least 6 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, currentPassword, newPassword } = req.body;

    // Get current user
    const [users] = await db.query(
      'SELECT * FROM users WHERE id = ?',
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = users[0];

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    // Prepare update query
    const updates = [];
    const values = [];

    // Update email if provided
    if (email && email !== user.email) {
      // Check if email already exists
      const [existingUsers] = await db.query(
        'SELECT id FROM users WHERE email = ? AND id != ?',
        [email, req.user.id]
      );

      if (existingUsers.length > 0) {
        return res.status(400).json({ error: 'Email already in use' });
      }

      updates.push('email = ?');
      values.push(email);
    }

    // Update password if provided
    if (newPassword) {
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      updates.push('password_hash = ?');
      values.push(hashedPassword);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No changes to update' });
    }

    // Add user ID for WHERE clause
    values.push(req.user.id);

    // Execute update
    await db.query(
      `UPDATE users SET ${updates.join(', ')}, updated_at = NOW() WHERE id = ?`,
      values
    );

    res.json({ 
      message: 'Profile updated successfully',
      updated: {
        email: email !== undefined,
        password: newPassword !== undefined
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
