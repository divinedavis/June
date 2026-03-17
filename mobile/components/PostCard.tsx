import React, { useState } from 'react';
import {
  View, Text, TouchableOpacity, StyleSheet, Alert
} from 'react-native';
import { Image } from 'expo-image';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../constants/colors';
import { postsAPI } from '../services/api';
import { useAuth } from '../hooks/useAuth';

interface Post {
  id: string;
  content: string;
  media_url?: string;
  like_count: number;
  repost_count: number;
  reply_count: number;
  view_count: number;
  created_at: string;
  is_liked: boolean;
  is_reposted: boolean;
  user: {
    id: string;
    username: string;
    display_name: string;
    avatar_url?: string;
    is_public: boolean;
  };
}

interface PostCardProps {
  post: Post;
  onDelete?: () => void;
  showBorder?: boolean;
}

const timeAgo = (dateStr: string) => {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'now';
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d`;
  return new Date(dateStr).toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
};

const formatCount = (n: number) => {
  if (n >= 1000000) return `${(n / 1000000).toFixed(1)}M`;
  if (n >= 1000) return `${(n / 1000).toFixed(1)}K`;
  return n > 0 ? n.toString() : '';
};

const PostCard: React.FC<PostCardProps> = ({ post, onDelete, showBorder = true }) => {
  const { user: currentUser } = useAuth();
  const [liked, setLiked] = useState(post.is_liked);
  const [reposted, setReposted] = useState(post.is_reposted);
  const [likeCount, setLikeCount] = useState(post.like_count);
  const [repostCount, setRepostCount] = useState(post.repost_count);

  const handleLike = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    const wasLiked = liked;
    setLiked(!liked);
    setLikeCount(prev => wasLiked ? prev - 1 : prev + 1);
    try {
      if (wasLiked) {
        await postsAPI.unlike(post.id);
      } else {
        await postsAPI.like(post.id);
      }
    } catch {
      setLiked(wasLiked);
      setLikeCount(prev => wasLiked ? prev + 1 : prev - 1);
    }
  };

  const handleRepost = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    const wasReposted = reposted;
    setReposted(!reposted);
    setRepostCount(prev => wasReposted ? prev - 1 : prev + 1);
    try {
      if (wasReposted) {
        await postsAPI.unrepost(post.id);
      } else {
        await postsAPI.repost(post.id);
      }
    } catch {
      setReposted(wasReposted);
      setRepostCount(prev => wasReposted ? prev + 1 : prev - 1);
    }
  };

  const handleDelete = () => {
    Alert.alert('Delete Post', 'Are you sure you want to delete this post?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete', style: 'destructive', onPress: async () => {
          try {
            await postsAPI.delete(post.id);
            onDelete?.();
          } catch (err: any) {
            Alert.alert('Error', err.message);
          }
        }
      },
    ]);
  };

  const navigateToProfile = () => {
    router.push(`/profile/${post.user.username}`);
  };

  const navigateToPost = () => {
    router.push(`/post/${post.id}`);
  };

  return (
    <View style={[styles.container, showBorder && styles.border]}>
      <TouchableOpacity onPress={navigateToProfile} style={styles.avatarContainer}>
        {post.user.avatar_url ? (
          <Image source={{ uri: post.user.avatar_url }} style={styles.avatar} contentFit="cover" />
        ) : (
          <View style={styles.avatarFallback}>
            <Text style={styles.avatarLetter}>
              {(post.user.display_name || post.user.username)[0].toUpperCase()}
            </Text>
          </View>
        )}
      </TouchableOpacity>

      <View style={styles.content}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={navigateToProfile} style={styles.userInfo}>
            <Text style={styles.displayName} numberOfLines={1}>
              {post.user.display_name || post.user.username}
            </Text>
            <Text style={styles.username} numberOfLines={1}>
              @{post.user.username}
            </Text>
            <Text style={styles.time}> · {timeAgo(post.created_at)}</Text>
          </TouchableOpacity>

          {currentUser?.id === post.user.id && (
            <TouchableOpacity onPress={handleDelete} style={styles.moreBtn} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
              <Ionicons name="ellipsis-horizontal" size={16} color={Colors.textTertiary} />
            </TouchableOpacity>
          )}
        </View>

        {/* Post content */}
        <TouchableOpacity onPress={navigateToPost} activeOpacity={0.9}>
          <Text style={styles.postText}>{post.content}</Text>
          {post.media_url && (
            <Image source={{ uri: post.media_url }} style={styles.media} contentFit="cover" />
          )}
        </TouchableOpacity>

        {/* Actions */}
        <View style={styles.actions}>
          <TouchableOpacity style={styles.actionBtn} onPress={navigateToPost}>
            <Ionicons name="chatbubble-outline" size={18} color={Colors.textTertiary} />
            <Text style={styles.actionCount}>{formatCount(post.reply_count)}</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionBtn} onPress={handleRepost}>
            <Ionicons
              name="repeat-outline"
              size={20}
              color={reposted ? Colors.repost : Colors.textTertiary}
            />
            <Text style={[styles.actionCount, reposted && { color: Colors.repost }]}>
              {formatCount(repostCount)}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.actionBtn} onPress={handleLike}>
            <Ionicons
              name={liked ? 'heart' : 'heart-outline'}
              size={18}
              color={liked ? Colors.like : Colors.textTertiary}
            />
            <Text style={[styles.actionCount, liked && { color: Colors.like }]}>
              {formatCount(likeCount)}
            </Text>
          </TouchableOpacity>

          <View style={styles.actionBtn}>
            <Ionicons name="eye-outline" size={17} color={Colors.textTertiary} />
            <Text style={styles.actionCount}>{formatCount(post.view_count)}</Text>
          </View>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.background,
  },
  border: {
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
  },
  avatarContainer: {
    marginRight: 12,
    marginTop: 2,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.surface,
  },
  avatarFallback: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarLetter: {
    color: Colors.accent,
    fontSize: 18,
    fontWeight: '600',
  },
  content: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  userInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  displayName: {
    color: Colors.textPrimary,
    fontWeight: '600',
    fontSize: 15,
    maxWidth: 130,
  },
  username: {
    color: Colors.textSecondary,
    fontSize: 14,
    marginLeft: 4,
    maxWidth: 100,
  },
  time: {
    color: Colors.textSecondary,
    fontSize: 14,
  },
  moreBtn: {
    padding: 4,
  },
  postText: {
    color: Colors.textPrimary,
    fontSize: 15,
    lineHeight: 21,
    marginBottom: 8,
  },
  media: {
    width: '100%',
    height: 220,
    borderRadius: 12,
    marginBottom: 10,
    backgroundColor: Colors.surface,
  },
  actions: {
    flexDirection: 'row',
    marginTop: 4,
    gap: 24,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  actionCount: {
    color: Colors.textTertiary,
    fontSize: 13,
  },
});

export default PostCard;
