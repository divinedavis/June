import React, { useState, useEffect } from 'react';
import {
  View, Text, ScrollView, StyleSheet, TouchableOpacity,
  FlatList, Alert, ActivityIndicator, RefreshControl
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Image } from 'expo-image';
import { router, useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/colors';
import PostCard from '../../components/PostCard';
import { usersAPI } from '../../services/api';
import { useAuth } from '../../hooks/useAuth';

export default function ProfileScreen() {
  const { username } = useLocalSearchParams<{ username: string }>();
  const { user: currentUser } = useAuth();
  const [profile, setProfile] = useState<any>(null);
  const [posts, setPosts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [postsLoading, setPostsLoading] = useState(false);
  const [following, setFollowing] = useState(false);
  const [cursor, setCursor] = useState<string | null>(null);

  const isOwnProfile = currentUser?.username === username;

  useEffect(() => {
    loadProfile();
  }, [username]);

  const loadProfile = async () => {
    setLoading(true);
    try {
      const [profileData, postsData] = await Promise.all([
        usersAPI.get(username as string) as any,
        usersAPI.posts(username as string) as any,
      ]);
      setProfile(profileData.user);
      setFollowing(profileData.user.is_following);
      setPosts(postsData.posts);
      setCursor(postsData.next_cursor);
    } catch (err: any) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleFollow = async () => {
    const wasFollowing = following;
    setFollowing(!following);
    setProfile((prev: any) => ({
      ...prev,
      follower_count: wasFollowing ? prev.follower_count - 1 : prev.follower_count + 1,
    }));
    try {
      if (wasFollowing) {
        await usersAPI.unfollow(username as string);
      } else {
        await usersAPI.follow(username as string);
      }
    } catch {
      setFollowing(wasFollowing);
      setProfile((prev: any) => ({
        ...prev,
        follower_count: wasFollowing ? prev.follower_count + 1 : prev.follower_count - 1,
      }));
    }
  };

  const handleLoadMorePosts = async () => {
    if (!cursor || postsLoading) return;
    setPostsLoading(true);
    try {
      const data: any = await usersAPI.posts(username as string, cursor);
      setPosts(prev => [...prev, ...data.posts]);
      setCursor(data.next_cursor);
    } catch {
    } finally {
      setPostsLoading(false);
    }
  };

  if (loading) {
    return (
      <View style={[styles.container, styles.centered]}>
        <ActivityIndicator color={Colors.accent} size="large" />
      </View>
    );
  }

  if (!profile) {
    return (
      <View style={[styles.container, styles.centered]}>
        <Text style={styles.errorText}>User not found</Text>
      </View>
    );
  }

  const Header = () => (
    <View>
      {/* Back + Actions */}
      <View style={styles.topBar}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Ionicons name="chevron-back" size={24} color={Colors.textPrimary} />
        </TouchableOpacity>
        <View style={styles.topBarRight}>
          {isOwnProfile && (
            <TouchableOpacity onPress={() => router.push('/profile/settings')} style={styles.iconBtn}>
              <Ionicons name="settings-outline" size={22} color={Colors.textPrimary} />
            </TouchableOpacity>
          )}
          {!isOwnProfile && (
            <TouchableOpacity
              onPress={() => router.push({
                pathname: '/(tabs)/dms',
                params: { startDm: profile.username }
              })}
              style={styles.iconBtn}
            >
              <Ionicons name="chatbubble-outline" size={20} color={Colors.textPrimary} />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* Avatar + Info */}
      <View style={styles.profileHeader}>
        <View style={styles.avatarRow}>
          {profile.avatar_url ? (
            <Image source={{ uri: profile.avatar_url }} style={styles.avatar} contentFit="cover" />
          ) : (
            <View style={styles.avatarFallback}>
              <Text style={styles.avatarLetter}>
                {(profile.display_name || profile.username)[0].toUpperCase()}
              </Text>
            </View>
          )}

          {!isOwnProfile && (
            <TouchableOpacity
              style={[styles.followBtn, following && styles.followingBtn]}
              onPress={handleFollow}
              activeOpacity={0.8}
            >
              <Text style={[styles.followBtnText, following && styles.followingBtnText]}>
                {following ? 'Following' : 'Follow'}
              </Text>
            </TouchableOpacity>
          )}
          {isOwnProfile && (
            <TouchableOpacity
              style={styles.editBtn}
              onPress={() => router.push('/profile/settings')}
              activeOpacity={0.8}
            >
              <Text style={styles.editBtnText}>Edit profile</Text>
            </TouchableOpacity>
          )}
        </View>

        <Text style={styles.displayName}>{profile.display_name || profile.username}</Text>
        <View style={styles.usernameRow}>
          <Text style={styles.username}>@{profile.username}</Text>
          {!profile.is_public && (
            <View style={styles.privateBadge}>
              <Ionicons name="lock-closed" size={11} color={Colors.textTertiary} />
              <Text style={styles.privateBadgeText}>Private</Text>
            </View>
          )}
        </View>

        {profile.bio && (
          <Text style={styles.bio}>{profile.bio}</Text>
        )}

        <Text style={styles.joinDate}>
          <Ionicons name="calendar-outline" size={13} color={Colors.textTertiary} />
          {' '}Joined {new Date(profile.created_at).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
        </Text>

        {/* Stats */}
        <View style={styles.stats}>
          <TouchableOpacity style={styles.stat}>
            <Text style={styles.statCount}>{profile.following_count}</Text>
            <Text style={styles.statLabel}>Following</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.stat}>
            <Text style={styles.statCount}>{profile.follower_count}</Text>
            <Text style={styles.statLabel}>Followers</Text>
          </TouchableOpacity>
        </View>
      </View>

      <View style={styles.postsDivider}>
        <Text style={styles.postsHeader}>Posts</Text>
      </View>
    </View>
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={posts}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <PostCard post={item} onDelete={() => setPosts(prev => prev.filter(p => p.id !== item.id))} />
        )}
        ListHeaderComponent={<Header />}
        ListFooterComponent={postsLoading ? <ActivityIndicator color={Colors.accent} style={{ padding: 20 }} /> : null}
        ListEmptyComponent={
          profile.can_view ? (
            <View style={styles.emptyPosts}>
              <Text style={styles.emptyPostsText}>No posts yet</Text>
            </View>
          ) : (
            <View style={styles.privateInfo}>
              <Ionicons name="lock-closed" size={36} color={Colors.textTertiary} />
              <Text style={styles.privateTitle}>This account is private</Text>
              <Text style={styles.privateSubtitle}>Follow to see their posts</Text>
            </View>
          )
        }
        onEndReached={handleLoadMorePosts}
        onEndReachedThreshold={0.3}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={loading} onRefresh={loadProfile} tintColor={Colors.accent} />}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  centered: { alignItems: 'center', justifyContent: 'center' },
  errorText: { color: Colors.textSecondary, fontSize: 16 },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 52,
    paddingBottom: 8,
  },
  backBtn: { padding: 4 },
  topBarRight: { flexDirection: 'row', gap: 8 },
  iconBtn: { padding: 8 },
  profileHeader: { paddingHorizontal: 16, paddingBottom: 16 },
  avatarRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    marginBottom: 12,
  },
  avatar: { width: 80, height: 80, borderRadius: 40 },
  avatarFallback: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: Colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarLetter: { color: Colors.accent, fontSize: 32, fontWeight: '700' },
  followBtn: {
    borderRadius: 50,
    paddingHorizontal: 20,
    paddingVertical: 9,
    backgroundColor: Colors.textPrimary,
  },
  followingBtn: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: Colors.border,
  },
  followBtnText: { color: Colors.background, fontSize: 15, fontWeight: '700' },
  followingBtnText: { color: Colors.textPrimary },
  editBtn: {
    borderRadius: 50,
    paddingHorizontal: 20,
    paddingVertical: 9,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  editBtnText: { color: Colors.textPrimary, fontSize: 15, fontWeight: '600' },
  displayName: { color: Colors.textPrimary, fontSize: 20, fontWeight: '700', marginBottom: 4 },
  usernameRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 10 },
  username: { color: Colors.textSecondary, fontSize: 15 },
  privateBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: Colors.surfaceElevated,
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 8,
  },
  privateBadgeText: { color: Colors.textTertiary, fontSize: 11 },
  bio: { color: Colors.textPrimary, fontSize: 15, lineHeight: 21, marginBottom: 10 },
  joinDate: { color: Colors.textTertiary, fontSize: 14, marginBottom: 14 },
  stats: { flexDirection: 'row', gap: 20 },
  stat: { flexDirection: 'row', gap: 4 },
  statCount: { color: Colors.textPrimary, fontSize: 15, fontWeight: '700' },
  statLabel: { color: Colors.textSecondary, fontSize: 15 },
  postsDivider: {
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: Colors.border,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  postsHeader: { color: Colors.textPrimary, fontSize: 16, fontWeight: '700' },
  emptyPosts: { alignItems: 'center', paddingTop: 40 },
  emptyPostsText: { color: Colors.textSecondary, fontSize: 15 },
  privateInfo: { alignItems: 'center', paddingTop: 60, gap: 10 },
  privateTitle: { color: Colors.textPrimary, fontSize: 18, fontWeight: '700' },
  privateSubtitle: { color: Colors.textSecondary, fontSize: 15 },
});
