const pool = require('../config/database');

/**
 * TikTok-style For You feed algorithm
 *
 * Score = (engagement_score * interest_multiplier) / (age_hours + 2)^1.5
 *
 * Factors:
 * - Engagement: likes (2pt), reposts (3pt), replies (1pt), views (0.1pt)
 * - Interest: based on user's past interactions with similar users
 * - Recency: decay over time using power law
 * - Social: boost posts from users you follow
 */
const getForYouFeed = async (userId, cursor = null, limit = 20) => {
  // Get users the current user follows (for follow boost)
  const followingResult = await pool.query(
    'SELECT following_id FROM follows WHERE follower_id = $1',
    [userId]
  );
  const followingIds = followingResult.rows.map(r => r.following_id);

  // Get user's recent liked authors (interest graph)
  const interestResult = await pool.query(
    `SELECT p.user_id, COUNT(*) as score
     FROM user_interactions ui
     JOIN posts p ON ui.post_id = p.id
     WHERE ui.user_id = $1
     AND ui.interaction_type IN ('like', 'repost', 'click')
     AND ui.created_at > NOW() - INTERVAL '7 days'
     GROUP BY p.user_id
     ORDER BY score DESC
     LIMIT 50`,
    [userId]
  );
  const interestMap = {};
  interestResult.rows.forEach(r => {
    interestMap[r.user_id] = Math.min(parseInt(r.score), 10);
  });

  // Get candidate posts (last 72 hours, not from private accounts the user doesn't follow)
  const cursorCondition = cursor ? `AND p.created_at < '${cursor}'` : '';

  const result = await pool.query(
    `SELECT p.*,
            u.username, u.display_name, u.avatar_url, u.is_public,
            EXISTS(SELECT 1 FROM likes WHERE user_id = $1 AND post_id = p.id) as is_liked,
            EXISTS(SELECT 1 FROM reposts WHERE user_id = $1 AND post_id = p.id) as is_reposted
     FROM posts p
     JOIN users u ON p.user_id = u.id
     WHERE p.reply_to_id IS NULL
       AND p.repost_of_id IS NULL
       AND p.user_id != $1
       AND p.created_at > NOW() - INTERVAL '72 hours'
       AND (
         u.is_public = true
         OR p.user_id = ANY($2::uuid[])
       )
       ${cursorCondition}
     ORDER BY p.created_at DESC
     LIMIT 500`,
    [userId, followingIds.length > 0 ? followingIds : [userId]]
  );

  // Score each post
  const scored = result.rows.map(post => {
    const ageHours = (Date.now() - new Date(post.created_at).getTime()) / 3600000;
    const engagementScore = (post.like_count * 2) + (post.repost_count * 3) + (post.reply_count * 1) + (post.view_count * 0.1);
    const interestMultiplier = 1 + (interestMap[post.user_id] || 0) * 0.2;
    const followBoost = followingIds.includes(post.user_id) ? 1.5 : 1;
    const recencyDecay = Math.pow(ageHours + 2, 1.5);
    const score = (engagementScore * interestMultiplier * followBoost) / recencyDecay;

    return { ...post, _score: score };
  });

  // Sort by score, take top N
  scored.sort((a, b) => b._score - a._score);
  const posts = scored.slice(0, limit);

  return {
    posts,
    next_cursor: posts.length === limit ? posts[posts.length - 1].created_at : null,
  };
};

/**
 * Following feed — chronological posts from followed users
 */
const getFollowingFeed = async (userId, cursor = null, limit = 20) => {
  const params = [userId, limit + 1];
  let query = `
    SELECT p.*, u.username, u.display_name, u.avatar_url, u.is_public,
           EXISTS(SELECT 1 FROM likes WHERE user_id = $1 AND post_id = p.id) as is_liked,
           EXISTS(SELECT 1 FROM reposts WHERE user_id = $1 AND post_id = p.id) as is_reposted
    FROM posts p
    JOIN follows f ON p.user_id = f.following_id
    JOIN users u ON p.user_id = u.id
    WHERE f.follower_id = $1
      AND p.reply_to_id IS NULL
  `;

  if (cursor) {
    query += ` AND p.created_at < $3`;
    params.push(cursor);
  }

  query += ` ORDER BY p.created_at DESC LIMIT $2`;

  const result = await pool.query(query, params);
  const posts = result.rows.slice(0, limit);

  return {
    posts,
    next_cursor: result.rows.length > limit ? posts[posts.length - 1].created_at : null,
  };
};

module.exports = { getForYouFeed, getFollowingFeed };
