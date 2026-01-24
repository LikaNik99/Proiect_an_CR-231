import express from 'express';
import { body, validationResult } from 'express-validator';
import { pool } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

// Get all boards for user
router.get('/', authenticate, async (req, res) => {
  try {
    const [boards] = await pool.query(`
      SELECT DISTINCT b.*, u.name as owner_name, u.email as owner_email,
        bm.role as user_role
      FROM boards b
      INNER JOIN users u ON b.owner_id = u.id
      INNER JOIN board_members bm ON b.id = bm.board_id
      WHERE bm.user_id = ?
      ORDER BY b.updated_at DESC
    `, [req.user.id]);

    res.json({
      success: true,
      boards
    });
  } catch (error) {
    console.error('Get boards error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Get single board
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [boards] = await pool.query(`
      SELECT b.*, u.name as owner_name, u.email as owner_email
      FROM boards b
      INNER JOIN users u ON b.owner_id = u.id
      INNER JOIN board_members bm ON b.id = bm.board_id
      WHERE b.id = ? AND bm.user_id = ?
    `, [req.params.id, req.user.id]);

    if (boards.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Board not found'
      });
    }

    // Get lists with cards
    const [lists] = await pool.query(`
      SELECT * FROM lists
      WHERE board_id = ?
      ORDER BY position
    `, [req.params.id]);

    // Get cards for each list
    for (let list of lists) {
      const [cards] = await pool.query(`
        SELECT c.*, 
          GROUP_CONCAT(DISTINCT l.id) as label_ids,
          GROUP_CONCAT(DISTINCT l.name) as label_names,
          GROUP_CONCAT(DISTINCT l.color) as label_colors
        FROM cards c
        LEFT JOIN card_labels cl ON c.id = cl.card_id
        LEFT JOIN labels l ON cl.label_id = l.id
        WHERE c.list_id = ?
        GROUP BY c.id
        ORDER BY c.position
      `, [list.id]);
      
      list.cards = cards.map(card => ({
        ...card,
        labels: card.label_ids ? card.label_ids.split(',').map((id, index) => ({
          id: parseInt(id),
          name: card.label_names.split(',')[index],
          color: card.label_colors.split(',')[index]
        })) : []
      }));
    }

    // Get board members
    const [members] = await pool.query(`
      SELECT u.id, u.name, u.email, u.avatar, bm.role
      FROM board_members bm
      INNER JOIN users u ON bm.user_id = u.id
      WHERE bm.board_id = ?
    `, [req.params.id]);

    res.json({
      success: true,
      board: {
        ...boards[0],
        lists,
        members
      }
    });
  } catch (error) {
    console.error('Get board error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Create board
router.post('/',
  authenticate,
  [
    body('title').trim().notEmpty().withMessage('Title is required')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { title, description, background } = req.body;

      const [result] = await pool.query(
        'INSERT INTO boards (title, description, background, owner_id) VALUES (?, ?, ?, ?)',
        [title, description || null, background || '#0079bf', req.user.id]
      );

      // Add owner as board member
      await pool.query(
        'INSERT INTO board_members (board_id, user_id, role) VALUES (?, ?, ?)',
        [result.insertId, req.user.id, 'owner']
      );

      // Emit socket event
      const io = req.app.get('io');
      io.emit('board-created', { boardId: result.insertId, userId: req.user.id });

      res.status(201).json({
        success: true,
        board: {
          id: result.insertId,
          title,
          description,
          background: background || '#0079bf',
          owner_id: req.user.id
        }
      });
    } catch (error) {
      console.error('Create board error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
);

// Update board
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { title, description, background } = req.body;

    // Check if user has access
    const [access] = await pool.query(
      'SELECT * FROM board_members WHERE board_id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (access.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await pool.query(
      'UPDATE boards SET title = ?, description = ?, background = ? WHERE id = ?',
      [title, description, background, req.params.id]
    );

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${req.params.id}`).emit('board-updated', {
      boardId: req.params.id,
      title,
      description,
      background
    });

    res.json({
      success: true,
      message: 'Board updated'
    });
  } catch (error) {
    console.error('Update board error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Delete board
router.delete('/:id', authenticate, async (req, res) => {
  try {
    // Check if user is owner
    const [boards] = await pool.query(
      'SELECT * FROM boards WHERE id = ? AND owner_id = ?',
      [req.params.id, req.user.id]
    );

    if (boards.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Only owner can delete board'
      });
    }

    await pool.query('DELETE FROM boards WHERE id = ?', [req.params.id]);

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${req.params.id}`).emit('board-deleted', {
      boardId: req.params.id
    });

    res.json({
      success: true,
      message: 'Board deleted'
    });
  } catch (error) {
    console.error('Delete board error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Add member to board
router.post('/:id/members', authenticate, async (req, res) => {
  try {
    const { email } = req.body;

    // Check if user is owner or member
    const [access] = await pool.query(
      'SELECT * FROM board_members WHERE board_id = ? AND user_id = ?',
      [req.params.id, req.user.id]
    );

    if (access.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Find user by email
    const [users] = await pool.query(
      'SELECT id, name, email, avatar FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Add member
    try {
      await pool.query(
        'INSERT INTO board_members (board_id, user_id, role) VALUES (?, ?, ?)',
        [req.params.id, users[0].id, 'member']
      );
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') {
        return res.status(400).json({
          success: false,
          message: 'User already a member'
        });
      }
      throw error;
    }

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${req.params.id}`).emit('member-added', {
      boardId: req.params.id,
      user: users[0]
    });

    res.status(201).json({
      success: true,
      member: users[0]
    });
  } catch (error) {
    console.error('Add member error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

export default router;
