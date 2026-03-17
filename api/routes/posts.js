const express = require('express');
const pool = require('../config/database');
const { authenticate, optionalAuth } = require('../middleware/auth');

const router = express.Router();

const formatPost = (row, currentUserId) => ({
  id: row.id,
  content: row.content,
  media_url: row.media_url,
  like_count: row.like_count,
  repost_count: row.repost_count,
  reply_count: row.reply_count,
  view_count: row.view_count,
  created_at: row.created_at,
  reply_to_id: row.reply_to_id,
  repost_of_id: row.repost_of_id,
  user: {
    id: row.user_id,
    username: row.username,
    display_name: row.display_name,
    avatar_url: row.avatar_url,
    is_public: row.is_public,
  },
  is_liked: row.is_liked || false,
  is_reposted: row.is_reposted || false,
});

// POST /posts — create a post
router.post('/', authenticate, async (req, res) => {
  const { content, media_url, reply_to_id } = req.body;

  if (!content || content.trim().length === 0) {
    return res.status(400).json({ error: 'Content is required' });
  }

  if (content.length > 240) {
    return res.status(400).json({ error: 'Content exceeds 240 characters' });
  }

  try {
    if (reply_to_id) {
      const parent = await pool.query('SELECT id FROM posts WHERE id = $1', [reply_to_id]);
      if (!parent.rows[0]) return res.status(404).json({ error: 'Parent post not found' });

      await pool.query(
        'UPDATE posts SET reply_count = reply_count + 1 WHERE id = $1',
        [reply_to_id]
      );
    }

    const result = await pool.query(
      `INSERT INTO posts (user_id, content, media_url, reply_to_id)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [req.user.id, content.trim(), media_url || null, reply_to_id || null]
    );

    const post = result.rows[0];

    // Check for mentions and create notifications
    const mentions = content.match(/@(\w+)/g);
    if (mentions) {
      for (const mention of mentions) {
        const mentionUsername = mention.slice(1).toLowerCase();
        const mentionedUser = await pool.query(
          'SELECT id FROM users WHERE username = $1',
          [mentionUsername]
        );
        if (mentionedUser.rows[0] && mentionedUser.rows[0].id !== req.user.id) {
          await pool.query(
            `INSERT INTO notifications (user_id, from_user_id, type, post_id)
             VALUES ($1, $2, 'mention', $3)`,
            [mentionedUser.rows[0].id, req.user.id, post.id]
          );
        }
      }
    }

    if (reply_to_id) {
      const parentPost = await pool.query('SELECT user_id FROM posts WHERE id = $1', [reply_to_id]);
      if (parentPost.rows[0] && parentPost.rows[0].user_id !== req.user.id) {
        await pool.query(
          `INSERT INTO notifications (user_id, from_user_id, type, post_id)
           VALUES ($1, $2, 'reply', $3)`,
          [parentPost.rows[0].user_id, req.user.id, post.id]
        );
      }
    }

    const fullPost = await pool.query(
      `SELECT p.*, u.username, u.display_name, u.avatar_url, u.is_public
       FROM posts p JOIN users u ON p.user_id = u.id WHERE p.id = $1`,
      [post.id]
    );

    res.status(201).json({ post: formatPost(fullPost.rows[0], req.user.id) });
  } catch (err) {
    console.error('Create post error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /posts/:id
router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, u.username, u.display_name, u.avatar_url, u.is_public,
              ${req.user ? `EXISTS(SELECT 1 FROM likes WHERE user_id = $2 AND post_id = p.id) as is_liked,
              EXISTS(SELECT 1 FROM reposts WHERE user_id = $2 AND post_id = p.id) as is_reposted` : 'false as is_liked, false as is_reposted'}
       FROM posts p JOIN users u ON p.user_id = u.id
       WHERE p.id = $1`,
      req.user ? [req.params.id, req.user.id] : [req.params.id]
    );

    if (!result.rows[0]) return res.status(404).json({ error: 'Post not found' });

    const post = result.rows[0];

    // Check private account access
    if (!post.is_public && (!req.user || req.user.id !== post.user_id)) {
      const isFollowing = req.user
        ? await pool.query('SELECT 1 FROM follows WHERE follower_id = $1 AND following_id = $2', [req.user.id, post.user_id])
        : { rows: [] };
      if (!isFollowing.rows[0]) return res.status(403).json({ error: 'This account is private' });
    }

    // Track view
    if (req.user) {
      await pool.query(
        `INSERT INTO user_interactions (user_id, post_id, interaction_type) VALUES ($1, $2, 'view') ON CONFLICT DO NOTHING`,
        [req.user.id, post.id]
      ).catch(() => {});
      await pool.query('UPDATE posts SET view_count = view_count + 1 WHERE id = $1', [post.id]);
    }

    res.json({ post: formatPost(post, req.user?.id) });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /posts/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM posts WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );

    if (!result.rows[0]) return res.status(404).json({ error: 'Post not found or not yours' });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /posts/:id/like
router.post('/:id/like', authenticate, async (req, res) => {
  try {
    await pool.query(
      'INSERT INTO likes (user_id, post_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.user.id, req.params.id]
    );
    await pool.query('UPDATE posts SET like_count = like_count + 1 WHERE id = $1', [req.params.id]);

    // Notify post owner
    const post = await pool.query('SELECT user_id FROM posts WHERE id = $1', [req.params.id]);
    if (post.rows[0] && post.rows[0].user_id !== req.user.id) {
      await pool.query(
        `INSERT INTO notifications (user_id, from_user_id, type, post_id) VALUES ($1, $2, 'like', $3)`,
        [post.rows[0].user_id, req.user.id, req.params.id]
      );
    }

    await pool.query(
      `INSERT INTO user_interactions (user_id, post_id, interaction_type) VALUES ($1, $2, 'like') ON CONFLICT DO NOTHING`,
      [req.user.id, req.params.id]
    ).catch(() => {});

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /posts/:id/like
router.delete('/:id/like', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM likes WHERE user_id = $1 AND post_id = $2 RETURNING user_id',
      [req.user.id, req.params.id]
    );

    if (result.rows[0]) {
      await pool.query(
        'UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = $1',
        [req.params.id]
      );
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /posts/:id/repost
router.post('/:id/repost', authenticate, async (req, res) => {
  try {
    await pool.query(
      'INSERT INTO reposts (user_id, post_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.user.id, req.params.id]
    );
    await pool.query(
      'UPDATE posts SET repost_count = repost_count + 1 WHERE id = $1',
      [req.params.id]
    );

    const post = await pool.query('SELECT user_id FROM posts WHERE id = $1', [req.params.id]);
    if (post.rows[0] && post.rows[0].user_id !== req.user.id) {
      await pool.query(
        `INSERT INTO notifications (user_id, from_user_id, type, post_id) VALUES ($1, $2, 'repost', $3)`,
        [post.rows[0].user_id, req.user.id, req.params.id]
      );
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /posts/:id/repost
router.delete('/:id/repost', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM reposts WHERE user_id = $1 AND post_id = $2 RETURNING user_id',
      [req.user.id, req.params.id]
    );
    if (result.rows[0]) {
      await pool.query(
        'UPDATE posts SET repost_count = GREATEST(repost_count - 1, 0) WHERE id = $1',
        [req.params.id]
      );
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /posts/:id/replies
router.get('/:id/replies', optionalAuth, async (req, res) => {
  const { cursor, limit = 20 } = req.query;
  try {
    const params = [req.params.id, parseInt(limit) + 1];
    let query = `
      SELECT p.*, u.username, u.display_name, u.avatar_url, u.is_public
      ${req.user ? `, EXISTS(SELECT 1 FROM likes WHERE user_id = $3 AND post_id = p.id) as is_liked,
                     EXISTS(SELECT 1 FROM reposts WHERE user_id = $3 AND post_id = p.id) as is_reposted` : ', false as is_liked, false as is_reposted'}
      FROM posts p JOIN users u ON p.user_id = u.id
      WHERE p.reply_to_id = $1
    `;
    if (cursor) {
      query += ` AND p.created_at < $${params.length + 1}`;
      params.push(cursor);
    }
    if (req.user) params.splice(2, 0, req.user.id);
    query += ` ORDER BY p.created_at DESC LIMIT $2`;

    const result = await pool.query(query, params);
    const posts = result.rows.slice(0, limit);
    const hasMore = result.rows.length > limit;

    res.json({
      posts: posts.map(p => formatPost(p, req.user?.id)),
      next_cursor: hasMore ? posts[posts.length - 1].created_at : null,
    });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
