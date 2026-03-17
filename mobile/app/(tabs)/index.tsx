import React, { useState, useCallback, useRef } from 'react';
import {
  View, Text, FlatList, StyleSheet, RefreshControl,
  TouchableOpacity, TextInput, Modal, Alert, ActivityIndicator,
  KeyboardAvoidingView, Platform
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/colors';
import PostCard from '../../components/PostCard';
import { feedAPI, postsAPI } from '../../services/api';
import { useAuth } from '../../hooks/useAuth';

const CHAR_LIMIT = 240;

export default function HomeScreen() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<'forYou' | 'following'>('forYou');
  const [forYouPosts, setForYouPosts] = useState<any[]>([]);
  const [followingPosts, setFollowingPosts] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [forYouCursor, setForYouCursor] = useState<string | null>(null);
  const [followingCursor, setFollowingCursor] = useState<string | null>(null);
  const [composeVisible, setComposeVisible] = useState(false);
  const [postText, setPostText] = useState('');
  const [posting, setPosting] = useState(false);
  const flatListRef = useRef<FlatList>(null);

  const fetchFeed = useCallback(async (tab: 'forYou' | 'following', refresh = false) => {
    setLoading(true);
    try {
      const cursor = refresh ? undefined : (tab === 'forYou' ? forYouCursor : followingCursor);
      const data: any = tab === 'forYou'
        ? await feedAPI.forYou(cursor ?? undefined)
        : await feedAPI.following(cursor ?? undefined);

      if (tab === 'forYou') {
        setForYouPosts(prev => refresh ? data.posts : [...prev, ...data.posts]);
        setForYouCursor(data.next_cursor);
      } else {
        setFollowingPosts(prev => refresh ? data.posts : [...prev, ...data.posts]);
        setFollowingCursor(data.next_cursor);
      }
    } catch (err: any) {
      if (!refresh) Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [forYouCursor, followingCursor]);

  React.useEffect(() => {
    fetchFeed('forYou', true);
    fetchFeed('following', true);
  }, []);

  const handleRefresh = () => {
    setRefreshing(true);
    fetchFeed(activeTab, true);
  };

  const handleLoadMore = () => {
    const cursor = activeTab === 'forYou' ? forYouCursor : followingCursor;
    if (cursor && !loading) {
      fetchFeed(activeTab);
    }
  };

  const handlePost = async () => {
    if (!postText.trim()) return;
    setPosting(true);
    try {
      const { post } = await postsAPI.create({ content: postText.trim() }) as any;
      setPostText('');
      setComposeVisible(false);
      setForYouPosts(prev => [post, ...prev]);
      setFollowingPosts(prev => [post, ...prev]);
    } catch (err: any) {
      Alert.alert('Error', err.message);
    } finally {
      setPosting(false);
    }
  };

  const handleDeletePost = (postId: string) => {
    setForYouPosts(prev => prev.filter(p => p.id !== postId));
    setFollowingPosts(prev => prev.filter(p => p.id !== postId));
  };

  const posts = activeTab === 'forYou' ? forYouPosts : followingPosts;
  const charsLeft = CHAR_LIMIT - postText.length;

  return (
    <View style={styles.container}>
      {/* Feed Tabs */}
      <View style={styles.feedTabs}>
        <TouchableOpacity
          style={[styles.feedTab, activeTab === 'forYou' && styles.feedTabActive]}
          onPress={() => setActiveTab('forYou')}
        >
          <Text style={[styles.feedTabText, activeTab === 'forYou' && styles.feedTabTextActive]}>
            For You
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.feedTab, activeTab === 'following' && styles.feedTabActive]}
          onPress={() => setActiveTab('following')}
        >
          <Text style={[styles.feedTabText, activeTab === 'following' && styles.feedTabTextActive]}>
            Following
          </Text>
        </TouchableOpacity>
      </View>

      {/* Feed */}
      <FlatList
        ref={flatListRef}
        data={posts}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <PostCard post={item} onDelete={() => handleDeletePost(item.id)} />
        )}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor={Colors.accent}
          />
        }
        onEndReached={handleLoadMore}
        onEndReachedThreshold={0.3}
        ListFooterComponent={
          loading && !refreshing ? (
            <ActivityIndicator color={Colors.accent} style={{ padding: 20 }} />
          ) : null
        }
        ListEmptyComponent={
          !loading ? (
            <View style={styles.emptyState}>
              <Ionicons name="newspaper-outline" size={48} color={Colors.textTertiary} />
              <Text style={styles.emptyTitle}>
                {activeTab === 'forYou' ? 'Nothing here yet' : 'Follow people to see their posts'}
              </Text>
              <Text style={styles.emptySubtitle}>
                {activeTab === 'forYou' ? 'Be the first to post something' : 'Explore the app to find people'}
              </Text>
            </View>
          ) : null
        }
        showsVerticalScrollIndicator={false}
      />

      {/* Compose FAB */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => setComposeVisible(true)}
        activeOpacity={0.85}
      >
        <Ionicons name="add" size={28} color="#000" />
      </TouchableOpacity>

      {/* Compose Modal */}
      <Modal
        visible={composeVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setComposeVisible(false)}
      >
        <View style={styles.composeModal}>
          <View style={styles.composeHeader}>
            <TouchableOpacity onPress={() => setComposeVisible(false)}>
              <Text style={styles.cancelBtn}>Cancel</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.postBtn, (!postText.trim() || posting) && styles.postBtnDisabled]}
              onPress={handlePost}
              disabled={!postText.trim() || posting}
            >
              {posting ? (
                <ActivityIndicator color="#000" size="small" />
              ) : (
                <Text style={styles.postBtnText}>Post</Text>
              )}
            </TouchableOpacity>
          </View>

          <KeyboardAvoidingView
            behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
            style={styles.composeBody}
          >
            <TextInput
              style={styles.composeInput}
              value={postText}
              onChangeText={setPostText}
              placeholder="What's on your mind?"
              placeholderTextColor={Colors.textPlaceholder}
              multiline
              maxLength={CHAR_LIMIT}
              autoFocus
              selectionColor={Colors.accent}
            />
            <View style={styles.composeFooter}>
              <Text style={[styles.charCount, charsLeft < 20 && styles.charCountWarning, charsLeft < 0 && styles.charCountError]}>
                {charsLeft}
              </Text>
            </View>
          </KeyboardAvoidingView>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  feedTabs: {
    flexDirection: 'row',
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
  },
  feedTab: {
    flex: 1,
    paddingVertical: 14,
    alignItems: 'center',
  },
  feedTabActive: {
    borderBottomWidth: 2,
    borderBottomColor: Colors.accent,
  },
  feedTabText: {
    color: Colors.textSecondary,
    fontSize: 15,
    fontWeight: '500',
  },
  feedTabTextActive: {
    color: Colors.textPrimary,
    fontWeight: '700',
  },
  emptyState: {
    alignItems: 'center',
    paddingTop: 80,
    gap: 12,
  },
  emptyTitle: {
    color: Colors.textPrimary,
    fontSize: 18,
    fontWeight: '600',
  },
  emptySubtitle: {
    color: Colors.textSecondary,
    fontSize: 14,
    textAlign: 'center',
    paddingHorizontal: 40,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: Colors.accent,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 8,
    elevation: 8,
  },
  composeModal: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  composeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
  },
  cancelBtn: {
    color: Colors.textSecondary,
    fontSize: 16,
  },
  postBtn: {
    backgroundColor: Colors.accent,
    borderRadius: 50,
    paddingHorizontal: 20,
    paddingVertical: 8,
  },
  postBtnDisabled: { opacity: 0.5 },
  postBtnText: {
    color: '#000',
    fontSize: 15,
    fontWeight: '700',
  },
  composeBody: { flex: 1 },
  composeInput: {
    flex: 1,
    color: Colors.textPrimary,
    fontSize: 18,
    padding: 20,
    textAlignVertical: 'top',
    lineHeight: 26,
  },
  composeFooter: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  charCount: {
    color: Colors.textSecondary,
    fontSize: 14,
  },
  charCountWarning: { color: Colors.accent },
  charCountError: { color: Colors.error },
});
