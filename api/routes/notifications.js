const express = require('express');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /notifications
router.get('/', authenticate, async (req, res) => {
  const { cursor, limit = 30 } = req.query;
  try {
    const params = [req.user.id, parseInt(limit) + 1];
    let query = `
      SELECT n.*, u.username as from_username, u.display_name as from_display_name, u.avatar_url as from_avatar
      FROM notifications n
      LEFT JOIN users u ON n.from_user_id = u.id
      WHERE n.user_id = $1
    `;
    if (cursor) {
      query += ` AND n.created_at < $3`;
      params.push(cursor);
    }
    query += ` ORDER BY n.created_at DESC LIMIT $2`;

    const result = await pool.query(query, params);
    const notifications = result.rows.slice(0, limit);

    res.json({
      notifications: notifications.map(n => ({
        id: n.id,
        type: n.type,
        post_id: n.post_id,
        read: n.read,
        created_at: n.created_at,
        from_user: {
          id: n.from_user_id,
          username: n.from_username,
          display_name: n.from_display_name,
          avatar_url: n.from_avatar,
        },
      })),
      unread_count: notifications.filter(n => !n.read).length,
      next_cursor: result.rows.length > limit ? notifications[notifications.length - 1].created_at : null,
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /notifications/unread-count
router.get('/unread-count', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND read = false',
      [req.user.id]
    );
    res.json({ count: parseInt(result.rows[0].count) });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// PATCH /notifications/read — mark all as read
router.patch('/read', authenticate, async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET read = true WHERE user_id = $1',
      [req.user.id]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// PATCH /notifications/:id/read
router.patch('/:id/read', authenticate, async (req, res) => {
  try {
    await pool.query(
      'UPDATE notifications SET read = true WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
