import express from 'express';
import { body, validationResult } from 'express-validator';
import { pool } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

// Get comments for card
router.get('/card/:cardId', authenticate, async (req, res) => {
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

    const [comments] = await pool.query(
      `SELECT co.*, u.name as user_name, u.email as user_email, u.avatar as user_avatar
       FROM comments co
       INNER JOIN users u ON co.user_id = u.id
       WHERE co.card_id = ?
       ORDER BY co.created_at ASC`,
      [req.params.cardId]
    );

    res.json({
      success: true,
      comments
    });
  } catch (error) {
    console.error('Get comments error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Create comment
router.post('/',
  authenticate,
  [
    body('content').trim().notEmpty().withMessage('Content is required'),
    body('cardId').isInt().withMessage('Valid card ID is required')
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

      const { content, cardId } = req.body;

      // Check card access
      const [cards] = await pool.query(
        `SELECT c.*, l.board_id, bm.user_id
         FROM cards c
         INNER JOIN lists l ON c.list_id = l.id
         INNER JOIN board_members bm ON l.board_id = bm.board_id
         WHERE c.id = ? AND bm.user_id = ?`,
        [cardId, req.user.id]
      );

      if (cards.length === 0) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      const [result] = await pool.query(
        'INSERT INTO comments (content, card_id, user_id) VALUES (?, ?, ?)',
        [content, cardId, req.user.id]
      );

      const comment = {
        id: result.insertId,
        content,
        card_id: cardId,
        user_id: req.user.id,
        user_name: req.user.name,
        user_email: req.user.email,
        user_avatar: req.user.avatar,
        created_at: new Date()
      };

      // Emit socket event
      const io = req.app.get('io');
      io.to(`board-${cards[0].board_id}`).emit('comment-created', {
        comment,
        cardId
      });

      res.status(201).json({
        success: true,
        comment
      });
    } catch (error) {
      console.error('Create comment error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
);

// Update comment
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { content } = req.body;

    // Check comment ownership
    const [comments] = await pool.query(
      `SELECT co.*, c.id as card_id, l.board_id
       FROM comments co
       INNER JOIN cards c ON co.card_id = c.id
       INNER JOIN lists l ON c.list_id = l.id
       WHERE co.id = ? AND co.user_id = ?`,
      [req.params.id, req.user.id]
    );

    if (comments.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await pool.query(
      'UPDATE comments SET content = ? WHERE id = ?',
      [content, req.params.id]
    );

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${comments[0].board_id}`).emit('comment-updated', {
      commentId: req.params.id,
      content
    });

    res.json({
      success: true,
      message: 'Comment updated'
    });
  } catch (error) {
    console.error('Update comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Delete comment
router.delete('/:id', authenticate, async (req, res) => {
  try {
    // Check comment ownership
    const [comments] = await pool.query(
      `SELECT co.*, c.id as card_id, l.board_id
       FROM comments co
       INNER JOIN cards c ON co.card_id = c.id
       INNER JOIN lists l ON c.list_id = l.id
       WHERE co.id = ? AND co.user_id = ?`,
      [req.params.id, req.user.id]
    );

    if (comments.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await pool.query('DELETE FROM comments WHERE id = ?', [req.params.id]);

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${comments[0].board_id}`).emit('comment-deleted', {
      commentId: req.params.id
    });

    res.json({
      success: true,
      message: 'Comment deleted'
    });
  } catch (error) {
    console.error('Delete comment error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

export default router;
