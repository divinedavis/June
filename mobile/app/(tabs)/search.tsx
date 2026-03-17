import React, { useState, useCallback } from 'react';
import {
  View, Text, TextInput, FlatList, StyleSheet,
  TouchableOpacity, ActivityIndicator
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import { Colors } from '../../constants/colors';
import PostCard from '../../components/PostCard';
import { searchAPI, usersAPI } from '../../services/api';
import { useAuth } from '../../hooks/useAuth';

export default function SearchScreen() {
  const { user: currentUser } = useAuth();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<{ users: any[]; posts: any[] }>({ users: [], posts: [] });
  const [trending, setTrending] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeType, setActiveType] = useState<'all' | 'users' | 'posts'>('all');
  const [searchFocused, setSearchFocused] = useState(false);

  React.useEffect(() => {
    loadTrending();
  }, []);

  const loadTrending = async () => {
    try {
      const data: any = await searchAPI.trending();
      setTrending(data.posts || []);
    } catch {}
  };

  const handleSearch = useCallback(async (q: string) => {
    if (!q.trim()) {
      setResults({ users: [], posts: [] });
      return;
    }
    setLoading(true);
    try {
      const data: any = await searchAPI.search(q.trim(), activeType);
      setResults({
        users: data.users || [],
        posts: data.posts || [],
      });
    } catch {
    } finally {
      setLoading(false);
    }
  }, [activeType]);

  React.useEffect(() => {
    const timer = setTimeout(() => handleSearch(query), 300);
    return () => clearTimeout(timer);
  }, [query, activeType]);

  const UserRow = ({ item }: { item: any }) => (
    <TouchableOpacity
      style={styles.userRow}
      onPress={() => router.push(`/profile/${item.username}`)}
    >
      {item.avatar_url ? (
        <Image source={{ uri: item.avatar_url }} style={styles.userAvatar} contentFit="cover" />
      ) : (
        <View style={styles.userAvatarFallback}>
          <Text style={styles.userAvatarLetter}>{(item.display_name || item.username)[0].toUpperCase()}</Text>
        </View>
      )}
      <View style={styles.userInfo}>
        <Text style={styles.userDisplayName}>{item.display_name || item.username}</Text>
        <Text style={styles.userUsername}>@{item.username}</Text>
        {item.bio && <Text style={styles.userBio} numberOfLines={1}>{item.bio}</Text>}
      </View>
      {!item.is_public && (
        <Ionicons name="lock-closed" size={14} color={Colors.textTertiary} />
      )}
    </TouchableOpacity>
  );

  const showQuery = query.trim().length > 0;
  const displayPosts = showQuery ? results.posts : trending;

  return (
    <View style={styles.container}>
      {/* Search bar */}
      <View style={styles.searchBar}>
        <Ionicons name="search" size={18} color={Colors.textTertiary} style={styles.searchIcon} />
        <TextInput
          style={styles.searchInput}
          value={query}
          onChangeText={setQuery}
          placeholder="Search June"
          placeholderTextColor={Colors.textPlaceholder}
          autoCorrect={false}
          returnKeyType="search"
          selectionColor={Colors.accent}
          onFocus={() => setSearchFocused(true)}
          onBlur={() => setSearchFocused(false)}
        />
        {query.length > 0 && (
          <TouchableOpacity onPress={() => setQuery('')} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
            <Ionicons name="close-circle" size={18} color={Colors.textTertiary} />
          </TouchableOpacity>
        )}
      </View>

      {/* Type filter (when searching) */}
      {showQuery && (
        <View style={styles.filterRow}>
          {(['all', 'users', 'posts'] as const).map(type => (
            <TouchableOpacity
              key={type}
              style={[styles.filterBtn, activeType === type && styles.filterBtnActive]}
              onPress={() => setActiveType(type)}
            >
              <Text style={[styles.filterText, activeType === type && styles.filterTextActive]}>
                {type.charAt(0).toUpperCase() + type.slice(1)}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      )}

      {loading ? (
        <ActivityIndicator color={Colors.accent} style={{ marginTop: 40 }} />
      ) : (
        <FlatList
          data={[]}
          keyExtractor={() => 'list'}
          renderItem={null}
          ListHeaderComponent={() => (
            <>
              {/* Users */}
              {showQuery && results.users.length > 0 && (activeType === 'all' || activeType === 'users') && (
                <View>
                  <Text style={styles.sectionTitle}>People</Text>
                  {results.users.map(user => <UserRow key={user.id} item={user} />)}
                </View>
              )}

              {/* Posts */}
              {(activeType === 'all' || activeType === 'posts') && (
                <View>
                  {showQuery ? (
                    <Text style={styles.sectionTitle}>Posts</Text>
                  ) : (
                    <Text style={styles.sectionTitle}>Trending</Text>
                  )}
                  {displayPosts.map(post => <PostCard key={post.id} post={post} />)}
                </View>
              )}

              {/* Empty state */}
              {showQuery && results.users.length === 0 && results.posts.length === 0 && (
                <View style={styles.emptyState}>
                  <Ionicons name="search-outline" size={48} color={Colors.textTertiary} />
                  <Text style={styles.emptyTitle}>No results for "{query}"</Text>
                </View>
              )}
            </>
          )}
          showsVerticalScrollIndicator={false}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    margin: 12,
    backgroundColor: Colors.surface,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  searchIcon: { marginRight: 8 },
  searchInput: {
    flex: 1,
    color: Colors.textPrimary,
    fontSize: 16,
  },
  filterRow: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    gap: 8,
    marginBottom: 8,
  },
  filterBtn: {
    paddingHorizontal: 16,
    paddingVertical: 7,
    borderRadius: 50,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  filterBtnActive: {
    backgroundColor: Colors.accent,
    borderColor: Colors.accent,
  },
  filterText: { color: Colors.textSecondary, fontSize: 14 },
  filterTextActive: { color: '#000', fontWeight: '600' },
  sectionTitle: {
    color: Colors.textPrimary,
    fontSize: 18,
    fontWeight: '700',
    padding: 16,
    paddingBottom: 8,
  },
  userRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
    gap: 12,
  },
  userAvatar: { width: 44, height: 44, borderRadius: 22 },
  userAvatarFallback: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  userAvatarLetter: { color: Colors.accent, fontSize: 18, fontWeight: '600' },
  userInfo: { flex: 1 },
  userDisplayName: { color: Colors.textPrimary, fontSize: 15, fontWeight: '600' },
  userUsername: { color: Colors.textSecondary, fontSize: 14 },
  userBio: { color: Colors.textSecondary, fontSize: 13, marginTop: 2 },
  emptyState: { alignItems: 'center', paddingTop: 80, gap: 12 },
  emptyTitle: { color: Colors.textSecondary, fontSize: 16 },
});
