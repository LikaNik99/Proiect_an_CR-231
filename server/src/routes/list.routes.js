import express from 'express';
import { body, validationResult } from 'express-validator';
import { pool } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = express.Router();

// Create list
router.post('/',
  authenticate,
  [
    body('title').trim().notEmpty().withMessage('Title is required'),
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

      const { title, boardId } = req.body;

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

      // Get max position
      const [maxPos] = await pool.query(
        'SELECT COALESCE(MAX(position), -1) as maxPos FROM lists WHERE board_id = ?',
        [boardId]
      );

      const [result] = await pool.query(
        'INSERT INTO lists (title, board_id, position) VALUES (?, ?, ?)',
        [title, boardId, maxPos[0].maxPos + 1]
      );

      // Emit socket event
      const io = req.app.get('io');
      io.to(`board-${boardId}`).emit('list-created', {
        list: {
          id: result.insertId,
          title,
          board_id: boardId,
          position: maxPos[0].maxPos + 1,
          cards: []
        }
      });

      res.status(201).json({
        success: true,
        list: {
          id: result.insertId,
          title,
          board_id: boardId,
          position: maxPos[0].maxPos + 1
        }
      });
    } catch (error) {
      console.error('Create list error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }
);

// Update list
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { title, position, color } = req.body;

    // Check access through board
    const [lists] = await pool.query(
      `SELECT l.*, bm.user_id 
       FROM lists l
       INNER JOIN board_members bm ON l.board_id = bm.board_id
       WHERE l.id = ? AND bm.user_id = ?`,
      [req.params.id, req.user.id]
    );

    if (lists.length === 0) {
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

    if (position !== undefined) {
      updates.push('position = ?');
      values.push(position);
    }

    if (color !== undefined) {
      updates.push('color = ?');
      values.push(color);
    }

    if (updates.length > 0) {
      values.push(req.params.id);
      await pool.query(
        `UPDATE lists SET ${updates.join(', ')} WHERE id = ?`,
        values
      );
    }

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${lists[0].board_id}`).emit('list-updated', {
      listId: req.params.id,
      title,
      position,
      color
    });

    res.json({
      success: true,
      message: 'List updated'
    });
  } catch (error) {
    console.error('Update list error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Delete list
router.delete('/:id', authenticate, async (req, res) => {
  try {
    // Check access
    const [lists] = await pool.query(
      `SELECT l.*, bm.user_id 
       FROM lists l
       INNER JOIN board_members bm ON l.board_id = bm.board_id
       WHERE l.id = ? AND bm.user_id = ?`,
      [req.params.id, req.user.id]
    );

    if (lists.length === 0) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await pool.query('DELETE FROM lists WHERE id = ?', [req.params.id]);

    // Emit socket event
    const io = req.app.get('io');
    io.to(`board-${lists[0].board_id}`).emit('list-deleted', {
      listId: req.params.id
    });

    res.json({
      success: true,
      message: 'List deleted'
    });
  } catch (error) {
    console.error('Delete list error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

export default router;
