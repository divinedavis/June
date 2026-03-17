const express = require('express');
const pool = require('../config/database');
const { optionalAuth } = require('../middleware/auth');

const router = express.Router();

// GET /search?q=term&type=users|posts|all
router.get('/', optionalAuth, async (req, res) => {
  const { q, type = 'all', limit = 20 } = req.query;

  if (!q || q.trim().length === 0) {
    return res.status(400).json({ error: 'Query parameter q is required' });
  }

  const searchTerm = q.trim();
  const results = {};

  try {
    if (type === 'users' || type === 'all') {
      const usersResult = await pool.query(
        `SELECT id, username, display_name, avatar_url, bio, follower_count, is_public,
                ts_rank(to_tsvector('english', username || ' ' || COALESCE(display_name, '')), plainto_tsquery($1)) as rank
         FROM users
         WHERE (
           username ILIKE $2
           OR display_name ILIKE $2
         )
         ORDER BY rank DESC, follower_count DESC
         LIMIT $3`,
        [searchTerm, `%${searchTerm}%`, parseInt(limit)]
      );
      results.users = usersResult.rows;
    }

    if (type === 'posts' || type === 'all') {
      const postsResult = await pool.query(
        `SELECT p.*, u.username, u.display_name, u.avatar_url, u.is_public,
                ${req.user ? `EXISTS(SELECT 1 FROM likes WHERE user_id = $3 AND post_id = p.id) as is_liked,
                              EXISTS(SELECT 1 FROM reposts WHERE user_id = $3 AND post_id = p.id) as is_reposted` : 'false as is_liked, false as is_reposted'}
         FROM posts p JOIN users u ON p.user_id = u.id
         WHERE p.content ILIKE $1
           AND p.reply_to_id IS NULL
           AND (u.is_public = true ${req.user ? `OR p.user_id = $3` : ''})
         ORDER BY p.created_at DESC
         LIMIT $2`,
        req.user
          ? [`%${searchTerm}%`, parseInt(limit), req.user.id]
          : [`%${searchTerm}%`, parseInt(limit)]
      );
      results.posts = postsResult.rows.map(p => ({
        id: p.id, content: p.content, media_url: p.media_url,
        like_count: p.like_count, repost_count: p.repost_count,
        reply_count: p.reply_count, created_at: p.created_at,
        user: { id: p.user_id, username: p.username, display_name: p.display_name, avatar_url: p.avatar_url },
        is_liked: p.is_liked, is_reposted: p.is_reposted,
      }));
    }

    res.json(results);
  } catch (err) {
    console.error('Search error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /search/trending — trending posts/topics
router.get('/trending', optionalAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, u.username, u.display_name, u.avatar_url,
              false as is_liked, false as is_reposted
       FROM posts p JOIN users u ON p.user_id = u.id
       WHERE p.created_at > NOW() - INTERVAL '24 hours'
         AND p.reply_to_id IS NULL
         AND u.is_public = true
       ORDER BY (p.like_count * 2 + p.repost_count * 3 + p.reply_count) DESC
       LIMIT 20`
    );

    res.json({
      posts: result.rows.map(p => ({
        id: p.id, content: p.content,
        like_count: p.like_count, repost_count: p.repost_count,
        reply_count: p.reply_count, created_at: p.created_at,
        user: { id: p.user_id, username: p.username, display_name: p.display_name, avatar_url: p.avatar_url },
      })),
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
