const express = require('express');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// GET /dms/conversations
router.get('/conversations', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT
         dc.id,
         dc.last_message_at,
         dc.created_at,
         u.id as other_user_id,
         u.username as other_username,
         u.display_name as other_display_name,
         u.avatar_url as other_avatar,
         (SELECT dm.encrypted_content FROM dm_messages dm
          WHERE dm.conversation_id = dc.id
          ORDER BY dm.created_at DESC LIMIT 1) as last_message_encrypted,
         (SELECT dm.created_at FROM dm_messages dm
          WHERE dm.conversation_id = dc.id
          ORDER BY dm.created_at DESC LIMIT 1) as last_message_time
       FROM dm_conversations dc
       JOIN dm_participants dp1 ON dc.id = dp1.conversation_id AND dp1.user_id = $1
       JOIN dm_participants dp2 ON dc.id = dp2.conversation_id AND dp2.user_id != $1
       JOIN users u ON dp2.user_id = u.id
       ORDER BY dc.last_message_at DESC`,
      [req.user.id]
    );

    res.json({
      conversations: result.rows.map(c => ({
        id: c.id,
        last_message_at: c.last_message_at,
        created_at: c.created_at,
        other_user: {
          id: c.other_user_id,
          username: c.other_username,
          display_name: c.other_display_name,
          avatar_url: c.other_avatar,
        },
        last_message_encrypted: c.last_message_encrypted,
        last_message_time: c.last_message_time,
      })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /dms/conversations — start or get existing conversation
router.post('/conversations', authenticate, async (req, res) => {
  const { username } = req.body;
  if (!username) return res.status(400).json({ error: 'Username is required' });

  try {
    const targetUser = await pool.query(
      'SELECT id, username, display_name, avatar_url, public_key FROM users WHERE username = $1',
      [username.toLowerCase()]
    );
    if (!targetUser.rows[0]) return res.status(404).json({ error: 'User not found' });

    const target = targetUser.rows[0];
    if (target.id === req.user.id) return res.status(400).json({ error: 'Cannot DM yourself' });

    // Check for existing conversation
    const existing = await pool.query(
      `SELECT dc.id FROM dm_conversations dc
       JOIN dm_participants dp1 ON dc.id = dp1.conversation_id AND dp1.user_id = $1
       JOIN dm_participants dp2 ON dc.id = dp2.conversation_id AND dp2.user_id = $2`,
      [req.user.id, target.id]
    );

    if (existing.rows[0]) {
      return res.json({
        conversation: { id: existing.rows[0].id, other_user: target },
      });
    }

    // Create new conversation
    const convo = await pool.query(
      'INSERT INTO dm_conversations DEFAULT VALUES RETURNING id'
    );
    await pool.query(
      'INSERT INTO dm_participants (conversation_id, user_id) VALUES ($1, $2), ($1, $3)',
      [convo.rows[0].id, req.user.id, target.id]
    );

    res.status(201).json({
      conversation: { id: convo.rows[0].id, other_user: target },
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /dms/conversations/:id/messages
router.get('/conversations/:id/messages', authenticate, async (req, res) => {
  const { cursor, limit = 30 } = req.query;

  try {
    // Verify user is in this conversation
    const access = await pool.query(
      'SELECT 1 FROM dm_participants WHERE conversation_id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (!access.rows[0]) return res.status(403).json({ error: 'Access denied' });

    const params = [req.params.id, parseInt(limit) + 1];
    let query = `
      SELECT dm.*, u.username, u.display_name, u.avatar_url
      FROM dm_messages dm
      JOIN users u ON dm.sender_id = u.id
      WHERE dm.conversation_id = $1
    `;
    if (cursor) {
      query += ` AND dm.created_at < $3`;
      params.push(cursor);
    }
    query += ` ORDER BY dm.created_at DESC LIMIT $2`;

    const result = await pool.query(query, params);
    const messages = result.rows.slice(0, limit);

    res.json({
      messages: messages.reverse().map(m => ({
        id: m.id,
        encrypted_content: m.encrypted_content,
        nonce: m.nonce,
        created_at: m.created_at,
        sender: {
          id: m.sender_id,
          username: m.username,
          display_name: m.display_name,
          avatar_url: m.avatar_url,
        },
      })),
      next_cursor: result.rows.length > limit ? messages[0]?.created_at : null,
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /dms/conversations/:id/messages
router.post('/conversations/:id/messages', authenticate, async (req, res) => {
  const { encrypted_content, nonce } = req.body;

  if (!encrypted_content || !nonce) {
    return res.status(400).json({ error: 'encrypted_content and nonce are required' });
  }

  try {
    const access = await pool.query(
      'SELECT 1 FROM dm_participants WHERE conversation_id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (!access.rows[0]) return res.status(403).json({ error: 'Access denied' });

    const result = await pool.query(
      `INSERT INTO dm_messages (conversation_id, sender_id, encrypted_content, nonce)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.params.id, req.user.id, encrypted_content, nonce]
    );

    await pool.query(
      'UPDATE dm_conversations SET last_message_at = NOW() WHERE id = $1',
      [req.params.id]
    );

    const message = result.rows[0];

    // Emit via socket (handled in socket/index.js)
    const io = req.app.get('io');
    if (io) {
      io.to(`conversation:${req.params.id}`).emit('new_message', {
        id: message.id,
        conversation_id: req.params.id,
        encrypted_content: message.encrypted_content,
        nonce: message.nonce,
        created_at: message.created_at,
        sender: {
          id: req.user.id,
          username: req.user.username,
          display_name: req.user.display_name,
          avatar_url: req.user.avatar_url,
        },
      });
    }

    res.status(201).json({
      message: {
        id: message.id,
        encrypted_content: message.encrypted_content,
        nonce: message.nonce,
        created_at: message.created_at,
        sender: { id: req.user.id, username: req.user.username },
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
