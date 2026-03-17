import React, { useState, useEffect } from 'react';
import {
  View, Text, FlatList, StyleSheet, ActivityIndicator,
  KeyboardAvoidingView, Platform, TextInput, TouchableOpacity, Alert
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/colors';
import PostCard from '../../components/PostCard';
import { postsAPI } from '../../services/api';
import { useAuth } from '../../hooks/useAuth';

const CHAR_LIMIT = 240;

export default function PostScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const { user } = useAuth();
  const [post, setPost] = useState<any>(null);
  const [replies, setReplies] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [replyText, setReplyText] = useState('');
  const [posting, setPosting] = useState(false);

  useEffect(() => {
    loadPost();
  }, [id]);

  const loadPost = async () => {
    setLoading(true);
    try {
      const [postData, repliesData] = await Promise.all([
        postsAPI.get(id as string) as any,
        postsAPI.replies(id as string) as any,
      ]);
      setPost(postData.post);
      setReplies(repliesData.posts);
    } catch (err: any) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleReply = async () => {
    if (!replyText.trim() || posting) return;
    setPosting(true);
    try {
      const { post: newReply } = await postsAPI.create({
        content: replyText.trim(),
        reply_to_id: id,
      }) as any;
      setReplyText('');
      setReplies(prev => [newReply, ...prev]);
      setPost((prev: any) => prev ? { ...prev, reply_count: prev.reply_count + 1 } : prev);
    } catch (err: any) {
      Alert.alert('Error', err.message);
    } finally {
      setPosting(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator color={Colors.accent} size="large" />
      </View>
    );
  }

  if (!post) {
    return (
      <View style={styles.centered}>
        <Text style={styles.errorText}>Post not found</Text>
      </View>
    );
  }

  const charsLeft = CHAR_LIMIT - replyText.length;

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      <FlatList
        data={replies}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <PostCard post={item} />}
        ListHeaderComponent={() => (
          <View>
            <PostCard post={post} showBorder={false} />
            <View style={styles.replyCountRow}>
              <Text style={styles.replyCount}>{post.reply_count} replies</Text>
            </View>
            <View style={styles.divider} />
          </View>
        )}
        ListEmptyComponent={
          <View style={styles.emptyReplies}>
            <Text style={styles.emptyRepliesText}>No replies yet. Be the first!</Text>
          </View>
        }
        showsVerticalScrollIndicator={false}
      />

      {/* Reply input */}
      <View style={styles.replyInputBar}>
        <TextInput
          style={styles.replyInput}
          value={replyText}
          onChangeText={setReplyText}
          placeholder={`Reply to @${post.user.username}...`}
          placeholderTextColor={Colors.textPlaceholder}
          multiline
          maxLength={CHAR_LIMIT}
          selectionColor={Colors.accent}
        />
        <View style={styles.replyActions}>
          {replyText.length > 0 && (
            <Text style={[styles.charCount, charsLeft < 20 && { color: Colors.accent }, charsLeft < 0 && { color: Colors.error }]}>
              {charsLeft}
            </Text>
          )}
          <TouchableOpacity
            style={[styles.replyBtn, (!replyText.trim() || posting) && styles.replyBtnDisabled]}
            onPress={handleReply}
            disabled={!replyText.trim() || posting}
          >
            {posting ? (
              <ActivityIndicator color="#000" size="small" />
            ) : (
              <Text style={styles.replyBtnText}>Reply</Text>
            )}
          </TouchableOpacity>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  centered: { flex: 1, backgroundColor: Colors.background, alignItems: 'center', justifyContent: 'center' },
  errorText: { color: Colors.textSecondary, fontSize: 16 },
  replyCountRow: { paddingHorizontal: 16, paddingTop: 12 },
  replyCount: { color: Colors.textSecondary, fontSize: 14 },
  divider: { height: StyleSheet.hairlineWidth, backgroundColor: Colors.border, marginTop: 12 },
  emptyReplies: { alignItems: 'center', paddingTop: 40 },
  emptyRepliesText: { color: Colors.textSecondary, fontSize: 15 },
  replyInputBar: {
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: Colors.border,
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: Colors.background,
  },
  replyInput: {
    color: Colors.textPrimary,
    fontSize: 16,
    maxHeight: 100,
    paddingVertical: 4,
  },
  replyActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    gap: 12,
    marginTop: 8,
  },
  charCount: { color: Colors.textSecondary, fontSize: 13 },
  replyBtn: {
    backgroundColor: Colors.accent,
    borderRadius: 50,
    paddingHorizontal: 18,
    paddingVertical: 8,
  },
  replyBtnDisabled: { opacity: 0.5 },
  replyBtnText: { color: '#000', fontSize: 14, fontWeight: '700' },
});
