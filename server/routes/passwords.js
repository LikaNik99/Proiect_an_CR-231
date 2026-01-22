const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const { encrypt, decrypt, generatePassword } = require('../utils/encryption');

// Apply authentication to all routes
router.use(authenticateToken);

/**
 * @route   GET /api/passwords
 * @desc    Get all passwords for current user
 * @access  Private
 */
router.get('/', async (req, res) => {
  try {
    console.log(`\n🔵 [GET PASSWORDS] User ${req.user.username} (ID: ${req.user.id}) requesting all passwords`);
    const [passwords] = await db.query(
      'SELECT id, website, username, email, notes, category, favorite, created_at, updated_at FROM passwords WHERE user_id = ? ORDER BY created_at DESC',
      [req.user.id]
    );
    console.log(`✓ [GET PASSWORDS] Found ${passwords.length} passwords`);

    res.json({ passwords });

  } catch (error) {
    console.error('Get passwords error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * @route   GET /api/passwords/:id
 * @desc    Get single password with decrypted password
 * @access  Private
 */
router.get('/:id', async (req, res) => {
  try {
    console.log(`\n🔵 [GET PASSWORD] User ${req.user.username} requesting password ID: ${req.params.id}`);
    const [passwords] = await db.query(
      'SELECT * FROM passwords WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (passwords.length === 0) {
      console.log(`⚠️  [GET PASSWORD] Password ID ${req.params.id} not found`);
      return res.status(404).json({ error: 'Password not found' });
    }

    const password = passwords[0];
    console.log(`✓ [GET PASSWORD] Password found for website: ${password.website}`);
    
    // Decrypt password
    console.log('🔓 [GET PASSWORD] Decrypting password...');
    const decryptedPassword = decrypt(password.encrypted_password, password.iv);
    console.log(`✓ [GET PASSWORD] Password decrypted successfully (length: ${decryptedPassword.length})`);

    res.json({
      password: {
        ...password,
        decrypted_password: decryptedPassword,
        encrypted_password: undefined, // Don't send encrypted version
        iv: undefined // Don't send IV
      }
    });

  } catch (error) {
    console.error('Get password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * @route   POST /api/passwords
 * @desc    Create new password entry
 * @access  Private
 */
router.post('/', [
  body('website').trim().notEmpty().withMessage('Website is required'),
  body('password').notEmpty().withMessage('Password is required')
], async (req, res) => {
  try {
    console.log(`\n🔵 [CREATE PASSWORD] User ${req.user.username} creating new password`);
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('❌ [CREATE PASSWORD] Validation failed:', errors.array());
      return res.status(400).json({ errors: errors.array() });
    }

    const { website, username, email, password, notes, category, favorite } = req.body;
    console.log(`📝 [CREATE PASSWORD] Website: ${website}, Username: ${username || 'N/A'}, Category: ${category || 'N/A'}`);

    // Encrypt password
    console.log('🔒 [CREATE PASSWORD] Encrypting password (AES-256-CBC)...');
    const { encryptedData, iv } = encrypt(password);
    console.log(`✓ [CREATE PASSWORD] Password encrypted (length: ${encryptedData.length})`);

    // Insert password
    console.log('💾 [CREATE PASSWORD] Saving to database...');
    const [result] = await db.query(
      'INSERT INTO passwords (user_id, website, username, email, encrypted_password, iv, notes, category, favorite) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [req.user.id, website, username || null, email || null, encryptedData, iv, notes || null, category || null, favorite || false]
    );
    console.log(`✅ [CREATE PASSWORD] SUCCESS - Password saved with ID: ${result.insertId}\n`);

    res.status(201).json({
      message: 'Password saved successfully',
      password: {
        id: result.insertId,
        website,
        username,
        email,
        notes,
        category,
        favorite
      }
    });

  } catch (error) {
    console.error('Create password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * @route   PUT /api/passwords/:id
 * @desc    Update password entry
 * @access  Private
 */
router.put('/:id', async (req, res) => {
  try {
    console.log(`\n🔵 [UPDATE PASSWORD] User ${req.user.username} updating password ID: ${req.params.id}`);
    const { website, username, email, password, notes, category, favorite } = req.body;

    // Check if password exists and belongs to user
    console.log('🔍 [UPDATE PASSWORD] Checking if password exists...');
    const [existing] = await db.query(
      'SELECT * FROM passwords WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (existing.length === 0) {
      console.log(`⚠️  [UPDATE PASSWORD] Password ID ${req.params.id} not found`);
      return res.status(404).json({ error: 'Password not found' });
    }
    console.log(`✓ [UPDATE PASSWORD] Password found for website: ${existing[0].website}`);

    let encryptedData = existing[0].encrypted_password;
    let iv = existing[0].iv;

    // If password is being updated, encrypt it
    if (password) {
      console.log('🔒 [UPDATE PASSWORD] Re-encrypting password...');
      const encrypted = encrypt(password);
      encryptedData = encrypted.encryptedData;
      iv = encrypted.iv;
      console.log('✓ [UPDATE PASSWORD] Password re-encrypted');
    }

    // Update password
    console.log('💾 [UPDATE PASSWORD] Updating database...');
    await db.query(
      'UPDATE passwords SET website = ?, username = ?, email = ?, encrypted_password = ?, iv = ?, notes = ?, category = ?, favorite = ? WHERE id = ? AND user_id = ?',
      [
        website || existing[0].website,
        username !== undefined ? username : existing[0].username,
        email !== undefined ? email : existing[0].email,
        encryptedData,
        iv,
        notes !== undefined ? notes : existing[0].notes,
        category !== undefined ? category : existing[0].category,
        favorite !== undefined ? favorite : existing[0].favorite,
        req.params.id,
        req.user.id
      ]
    );
    console.log(`✅ [UPDATE PASSWORD] SUCCESS - Password ID ${req.params.id} updated\n`);

    res.json({ message: 'Password updated successfully' });

  } catch (error) {
    console.error('Update password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * @route   DELETE /api/passwords/:id
 * @desc    Delete password entry
 * @access  Private
 */
router.delete('/:id', async (req, res) => {
  try {
    console.log(`\n🔵 [DELETE PASSWORD] User ${req.user.username} deleting password ID: ${req.params.id}`);
    const [result] = await db.query(
      'DELETE FROM passwords WHERE id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (result.affectedRows === 0) {
      console.log(`⚠️  [DELETE PASSWORD] Password ID ${req.params.id} not found`);
      return res.status(404).json({ error: 'Password not found' });
    }

    console.log(`✅ [DELETE PASSWORD] SUCCESS - Password ID ${req.params.id} deleted\n`);
    res.json({ message: 'Password deleted successfully' });

  } catch (error) {
    console.error('Delete password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * @route   POST /api/passwords/generate
 * @desc    Generate a random secure password
 * @access  Private
 */
router.post('/generate', async (req, res) => {
  try {
    const { length } = req.body;
    console.log(`\n🔵 [GENERATE PASSWORD] User ${req.user.username} generating password (length: ${length || 16})`);
    const password = generatePassword(length || 16);
    console.log(`✓ [GENERATE PASSWORD] Password generated successfully\n`);
    
    res.json({ password });

  } catch (error) {
    console.error('Generate password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
