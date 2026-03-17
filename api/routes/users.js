const express = require('express');
const pool = require('../config/database');
const { authenticate, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// GET /users/:username
router.get('/:username', optionalAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, username, display_name, bio, avatar_url, is_public,
              follower_count, following_count, post_count, created_at, public_key
       FROM users WHERE username = $1`,
      [req.params.username.toLowerCase()]
    );

    if (!result.rows[0]) return res.status(404).json({ error: 'User not found' });

    const user = result.rows[0];
    let is_following = false;
    let is_follower = false;

    if (req.user) {
      const followCheck = await pool.query(
        'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
        [req.user.id, user.id]
      );
      is_following = followCheck.rows.length > 0;

      const followerCheck = await pool.query(
        'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
        [user.id, req.user.id]
      );
      is_follower = followerCheck.rows.length > 0;
    }

    const canViewContent = user.is_public || (req.user && (req.user.id === user.id || is_following));

    res.json({ user: { ...user, is_following, is_follower, can_view: canViewContent } });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /users/:username/posts
router.get('/:username/posts', optionalAuth, async (req, res) => {
  const { cursor, limit = 20 } = req.query;

  try {
    const userResult = await pool.query(
      'SELECT id, is_public FROM users WHERE username = $1',
      [req.params.username.toLowerCase()]
    );

    if (!userResult.rows[0]) return res.status(404).json({ error: 'User not found' });

    const profileUser = userResult.rows[0];

    if (!profileUser.is_public && req.user?.id !== profileUser.id) {
      const followCheck = await pool.query(
        'SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2',
        [req.user?.id, profileUser.id]
      );
      if (!followCheck.rows[0]) return res.status(403).json({ error: 'This account is private' });
    }

    const params = [profileUser.id, parseInt(limit) + 1];
    let query = `
      SELECT p.*, u.username, u.display_name, u.avatar_url, u.is_public
      ${req.user ? `, EXISTS(SELECT 1 FROM likes WHERE user_id = $3 AND post_id = p.id) as is_liked,
                     EXISTS(SELECT 1 FROM reposts WHERE user_id = $3 AND post_id = p.id) as is_reposted` : ', false as is_liked, false as is_reposted'}
      FROM posts p JOIN users u ON p.user_id = u.id
      WHERE p.user_id = $1 AND p.reply_to_id IS NULL
    `;

    if (cursor) {
      query += ` AND p.created_at < $${params.length + 1}`;
      params.push(cursor);
    }
    if (req.user) params.splice(2, 0, req.user.id);
    query += ` ORDER BY p.created_at DESC LIMIT $2`;

    const result = await pool.query(query, params);
    const posts = result.rows.slice(0, limit);

    res.json({
      posts: posts.map(p => ({
        id: p.id, content: p.content, media_url: p.media_url,
        like_count: p.like_count, repost_count: p.repost_count,
        reply_count: p.reply_count, view_count: p.view_count,
        created_at: p.created_at,
        user: { id: p.user_id, username: p.username, display_name: p.display_name, avatar_url: p.avatar_url, is_public: p.is_public },
        is_liked: p.is_liked || false,
        is_reposted: p.is_reposted || false,
      })),
      next_cursor: result.rows.length > limit ? posts[posts.length - 1].created_at : null,
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /users/:username/follow
router.post('/:username/follow', authenticate, async (req, res) => {
  try {
    const target = await pool.query(
      'SELECT id FROM users WHERE username = $1',
      [req.params.username.toLowerCase()]
    );

    if (!target.rows[0]) return res.status(404).json({ error: 'User not found' });
    if (target.rows[0].id === req.user.id) return res.status(400).json({ error: 'Cannot follow yourself' });

    await pool.query(
      'INSERT INTO follows (follower_id, following_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.user.id, target.rows[0].id]
    );

    await pool.query(
      `INSERT INTO notifications (user_id, from_user_id, type) VALUES ($1, $2, 'follow') ON CONFLICT DO NOTHING`,
      [target.rows[0].id, req.user.id]
    ).catch(() => {});

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /users/:username/follow
router.delete('/:username/follow', authenticate, async (req, res) => {
  try {
    const target = await pool.query(
      'SELECT id FROM users WHERE username = $1',
      [req.params.username.toLowerCase()]
    );
    if (!target.rows[0]) return res.status(404).json({ error: 'User not found' });

    await pool.query(
      'DELETE FROM follows WHERE follower_id = $1 AND following_id = $2',
      [req.user.id, target.rows[0].id]
    );

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /users/:username/followers
router.get('/:username/followers', optionalAuth, async (req, res) => {
  try {
    const user = await pool.query('SELECT id FROM users WHERE username = $1', [req.params.username.toLowerCase()]);
    if (!user.rows[0]) return res.status(404).json({ error: 'User not found' });

    const result = await pool.query(
      `SELECT u.id, u.username, u.display_name, u.avatar_url, u.bio
       FROM follows f JOIN users u ON f.follower_id = u.id
       WHERE f.following_id = $1 ORDER BY f.created_at DESC LIMIT 50`,
      [user.rows[0].id]
    );
    res.json({ users: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /users/:username/following
router.get('/:username/following', optionalAuth, async (req, res) => {
  try {
    const user = await pool.query('SELECT id FROM users WHERE username = $1', [req.params.username.toLowerCase()]);
    if (!user.rows[0]) return res.status(404).json({ error: 'User not found' });

    const result = await pool.query(
      `SELECT u.id, u.username, u.display_name, u.avatar_url, u.bio
       FROM follows f JOIN users u ON f.following_id = u.id
       WHERE f.follower_id = $1 ORDER BY f.created_at DESC LIMIT 50`,
      [user.rows[0].id]
    );
    res.json({ users: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /users/me — update profile
router.put('/me', authenticate, async (req, res) => {
  const { display_name, bio, avatar_url, is_public } = req.body;

  try {
    const result = await pool.query(
      `UPDATE users SET
        display_name = COALESCE($1, display_name),
        bio = COALESCE($2, bio),
        avatar_url = COALESCE($3, avatar_url),
        is_public = COALESCE($4, is_public),
        updated_at = NOW()
       WHERE id = $5
       RETURNING id, username, email, display_name, bio, avatar_url, is_public, follower_count, following_count, post_count`,
      [display_name, bio, avatar_url, is_public, req.user.id]
    );

    res.json({ user: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
