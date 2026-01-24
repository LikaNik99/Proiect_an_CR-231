import express from 'express';
import { body, validationResult } from 'express-validator';
import { pool } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

// Create card
router.post('/',
  authenticate,
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('listId').isInt().withMessage('Valid list ID is required')
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

      const { title, description, listId, dueDate } = req.body;

      // Check list access
      const [lists] = await pool.query(
        `SELECT l.*, bm.user_id, l.board_id
         FROM lists l
         INNER JOIN board_members bm ON l.board_id = bm.board_id
         WHERE l.id = ? AND bm.user_id = ?`,
        [listId, req.user.id]
      );

      if (lists.length === 0) {
        return res.status(403).json({
          success: false,
          message: 'Access denied'
        });
      }

      // Get max position
      const [maxPos] = await pool.query(
        'SELECT COALESCE(MAX(position), -1) as maxPos FROM cards WHERE list_id = ?',
        [listId]
      );

      const [result] = await pool.query(
        'INSERT INTO cards (title, description, list_id, position, due_date) VALUES (?, ?, ?, ?, ?)',
        [title, description || null, listId, maxPos[0].maxPos + 1, dueDate || null]
      );

      const card = {
        id: result.insertId,
        title,
        description,
        list_id: listId,
        position: maxPos[0].maxPos + 1,
        due_date: dueDate || null,
        labels: []
      };

      // Emit socket event
      const io = req.app.get('io');
      io.to(`board-${lists[0].board_id}`).emit('card-created', { card, listId });

      res.status(201).json({
        success: true,
        card
      });
    } catch (error) {
      console.error('Create card error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
);

// Update card
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { title, description, listId, position, dueDate } = req.body;

    // Check access
    const [cards] = await pool.query(
      `SELECT c.*, l.board_id, bm.user_id
       FROM cards c
       INNER JOIN lists l ON c.list_id = l.id
       INNER JOIN board_members bm ON l.board_id = bm.board_id
       WHERE c.id = ? AND bm.user_id = ?`,
      [req.params.id, req.user.id]
    );

    if (cards.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const updates = [];
    const values = [];

    if (title !== undefined) {
      updates.push('title = ?');
      values.push(title);
    }
    if (description !== undefined) {
      updates.push('description = ?');
      values.push(description);
    }
    if (listId !== undefined) {
      updates.push('list_id = ?');
      values.push(listId);
    }
    if (position !== undefined) {
      updates.push('position = ?');
      values.push(position);
    }
    if (dueDate !== undefined) {
      updates.push('due_date = ?');
      values.push(dueDate);
    }

    if (updates.length > 0) {
      values.push(req.params.id);
      await pool.query(
        `UPDATE cards SET ${updates.join(', ')} WHERE id = ?`,
        values
      );
    }

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${cards[0].board_id}`).emit('card-updated', {
      cardId: req.params.id,
      updates: { title, description, listId, position, dueDate }
    });

    res.json({
      success: true,
      message: 'Card updated'
    });
  } catch (error) {
    console.error('Update card error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Delete card
router.delete('/:id', authenticate, async (req, res) => {
  try {
    // Check access
    const [cards] = await pool.query(
      `SELECT c.*, l.board_id, bm.user_id
       FROM cards c
       INNER JOIN lists l ON c.list_id = l.id
       INNER JOIN board_members bm ON l.board_id = bm.board_id
       WHERE c.id = ? AND bm.user_id = ?`,
      [req.params.id, req.user.id]
    );

    if (cards.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await pool.query('DELETE FROM cards WHERE id = ?', [req.params.id]);

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${cards[0].board_id}`).emit('card-deleted', {
      cardId: req.params.id
    });

    res.json({
      success: true,
      message: 'Card deleted'
    });
  } catch (error) {
    console.error('Delete card error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

export default router;
