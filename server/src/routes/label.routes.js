import express from 'express';
import { body, validationResult } from 'express-validator';
import { pool } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

// Create label
router.post('/',
  authenticate,
  [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('color').trim().notEmpty().withMessage('Color is required'),
    body('boardId').isInt().withMessage('Valid board ID is required')
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

      const { name, color, boardId } = req.body;

      // Check board access
      const [access] = await pool.query(
        'SELECT * FROM board_members WHERE board_id = ? AND user_id = ?',
        [boardId, req.user.id]
      );

      if (access.length === 0) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      const [result] = await pool.query(
        'INSERT INTO labels (name, color, board_id) VALUES (?, ?, ?)',
        [name, color, boardId]
      );

      const label = {
        id: result.insertId,
        name,
        color,
        board_id: boardId
      };

      // Emit socket event
      const io = req.app.get('io');
      io.to(`board-${boardId}`).emit('label-created', { label });

      res.status(201).json({
        success: true,
        label
      });
    } catch (error) {
      console.error('Create label error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
);

// Get labels for board
router.get('/board/:boardId', authenticate, async (req, res) => {
  try {
    // Check board access
    const [access] = await pool.query(
      'SELECT * FROM board_members WHERE board_id = ? AND user_id = ?',
      [req.params.boardId, req.user.id]
    );

    if (access.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const [labels] = await pool.query(
      'SELECT * FROM labels WHERE board_id = ?',
      [req.params.boardId]
    );

    res.json({
      success: true,
      labels
    });
  } catch (error) {
    console.error('Get labels error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Add label to card
router.post('/card/:cardId',
  authenticate,
  [body('labelId').isInt().withMessage('Valid label ID is required')],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          success: false,
          errors: errors.array()
        });
      }

      const { labelId } = req.body;

      // Check card access
      const [cards] = await pool.query(
        `SELECT c.*, l.board_id, bm.user_id
         FROM cards c
         INNER JOIN lists l ON c.list_id = l.id
         INNER JOIN board_members bm ON l.board_id = bm.board_id
         WHERE c.id = ? AND bm.user_id = ?`,
        [req.params.cardId, req.user.id]
      );

      if (cards.length === 0) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      try {
        await pool.query(
          'INSERT INTO card_labels (card_id, label_id) VALUES (?, ?)',
          [req.params.cardId, labelId]
        );
      } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
          return res.status(400).json({
            success: false,
            message: 'Label already added'
          });
        }
        throw error;
      }

      // Get label info
      const [labels] = await pool.query('SELECT * FROM labels WHERE id = ?', [labelId]);

      // Emit socket event
      const io = req.app.get('io');
      io.to(`board-${cards[0].board_id}`).emit('card-label-added', {
        cardId: req.params.cardId,
        label: labels[0]
      });

      res.status(201).json({
        success: true,
        message: 'Label added to card'
      });
    } catch (error) {
      console.error('Add label to card error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
);

// Remove label from card
router.delete('/card/:cardId/:labelId', authenticate, async (req, res) => {
  try {
    // Check card access
    const [cards] = await pool.query(
      `SELECT c.*, l.board_id, bm.user_id
       FROM cards c
       INNER JOIN lists l ON c.list_id = l.id
       INNER JOIN board_members bm ON l.board_id = bm.board_id
       WHERE c.id = ? AND bm.user_id = ?`,
      [req.params.cardId, req.user.id]
    );

    if (cards.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await pool.query(
      'DELETE FROM card_labels WHERE card_id = ? AND label_id = ?',
      [req.params.cardId, req.params.labelId]
    );

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${cards[0].board_id}`).emit('card-label-removed', {
      cardId: req.params.cardId,
      labelId: req.params.labelId
    });

    res.json({
      success: true,
      message: 'Label removed from card'
    });
  } catch (error) {
    console.error('Remove label from card error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

export default router;
