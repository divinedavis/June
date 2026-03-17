const express = require('express');
const { authenticate } = require('../middleware/auth');
const { getForYouFeed, getFollowingFeed } = require('../services/algorithm');

const router = express.Router();

const formatPost = (row) => ({
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

// GET /feed/for-you
router.get('/for-you', authenticate, async (req, res) => {
  try {
    const { cursor, limit } = req.query;
    const data = await getForYouFeed(req.user.id, cursor, parseInt(limit) || 20);
    res.json({
      posts: data.posts.map(formatPost),
      next_cursor: data.next_cursor,
    });
  } catch (err) {
    console.error('For You feed error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /feed/following
router.get('/following', authenticate, async (req, res) => {
  try {
    const { cursor, limit } = req.query;
    const data = await getFollowingFeed(req.user.id, cursor, parseInt(limit) || 20);
    res.json({
      posts: data.posts.map(formatPost),
      next_cursor: data.next_cursor,
    });
  } catch (err) {
    console.error('Following feed error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
