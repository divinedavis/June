import React, { useState, useCallback } from 'react';
import {
  View, Text, FlatList, StyleSheet,
  TouchableOpacity, RefreshControl, ActivityIndicator
} from 'react-native';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/colors';
import { notificationsAPI } from '../../services/api';

const NOTIFICATION_ICONS: Record<string, { icon: string; color: string }> = {
  like: { icon: 'heart', color: Colors.like },
  repost: { icon: 'repeat', color: Colors.repost },
  follow: { icon: 'person-add', color: Colors.accent },
  reply: { icon: 'chatbubble', color: '#1D9BF0' },
  mention: { icon: 'at', color: Colors.accent },
};

const NOTIFICATION_TEXT: Record<string, string> = {
  like: 'liked your post',
  repost: 'reposted your post',
  follow: 'followed you',
  reply: 'replied to your post',
  mention: 'mentioned you',
};

const timeAgo = (dateStr: string) => {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'now';
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  return `${days}d`;
};

export default function AlertsScreen() {
  const [notifications, setNotifications] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  React.useEffect(() => {
    loadNotifications(true);
  }, []);

  const loadNotifications = async (refresh = false) => {
    if (refresh) setRefreshing(true); else setLoading(true);
    try {
      const data: any = await notificationsAPI.list();
      setNotifications(data.notifications);
      // Mark all as read
      notificationsAPI.markAllRead().catch(() => {});
    } catch {
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const handlePress = (notification: any) => {
    if (notification.type === 'follow') {
      router.push(`/profile/${notification.from_user.username}`);
    } else if (notification.post_id) {
      router.push(`/post/${notification.post_id}`);
    }
  };

  const renderItem = ({ item }: { item: any }) => {
    const meta = NOTIFICATION_ICONS[item.type] || { icon: 'notifications', color: Colors.accent };

    return (
      <TouchableOpacity
        style={[styles.notifItem, !item.read && styles.notifItemUnread]}
        onPress={() => handlePress(item)}
        activeOpacity={0.7}
      >
        {/* Icon badge */}
        <View style={[styles.iconBadge, { backgroundColor: `${meta.color}20` }]}>
          <Ionicons name={meta.icon as any} size={20} color={meta.color} />
        </View>

        {/* Avatar */}
        <View style={styles.notifContent}>
          <TouchableOpacity onPress={() => router.push(`/profile/${item.from_user.username}`)}>
            {item.from_user.avatar_url ? (
              <Image source={{ uri: item.from_user.avatar_url }} style={styles.avatar} contentFit="cover" />
            ) : (
              <View style={styles.avatarFallback}>
                <Text style={styles.avatarLetter}>
                  {(item.from_user.display_name || item.from_user.username)?.[0]?.toUpperCase()}
                </Text>
              </View>
            )}
          </TouchableOpacity>

          <View style={styles.notifText}>
            <Text style={styles.notifBody}>
              <Text style={styles.notifName}>{item.from_user.display_name || item.from_user.username} </Text>
              <Text style={styles.notifAction}>{NOTIFICATION_TEXT[item.type] || 'interacted with you'}</Text>
            </Text>
            <Text style={styles.notifTime}>{timeAgo(item.created_at)}</Text>
          </View>

          {!item.read && <View style={styles.unreadDot} />}
        </View>
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.container}>
      <FlatList
        data={notifications}
        keyExtractor={(item) => item.id}
        renderItem={renderItem}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => loadNotifications(true)}
            tintColor={Colors.accent}
          />
        }
        ListFooterComponent={loading && !refreshing ? <ActivityIndicator color={Colors.accent} style={{ padding: 20 }} /> : null}
        ListEmptyComponent={
          !loading ? (
            <View style={styles.emptyState}>
              <Ionicons name="notifications-outline" size={48} color={Colors.textTertiary} />
              <Text style={styles.emptyTitle}>No notifications yet</Text>
              <Text style={styles.emptySubtitle}>When someone likes, reposts, or follows you, you'll see it here</Text>
            </View>
          ) : null
        }
        showsVerticalScrollIndicator={false}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  notifItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
    gap: 12,
  },
  notifItemUnread: { backgroundColor: Colors.accentDim },
  iconBadge: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  notifContent: { flex: 1, flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  avatar: { width: 40, height: 40, borderRadius: 20 },
  avatarFallback: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarLetter: { color: Colors.accent, fontSize: 16, fontWeight: '600' },
  notifText: { flex: 1 },
  notifBody: { color: Colors.textSecondary, fontSize: 15, lineHeight: 21 },
  notifName: { color: Colors.textPrimary, fontWeight: '600' },
  notifAction: { color: Colors.textSecondary },
  notifTime: { color: Colors.textTertiary, fontSize: 13, marginTop: 3 },
  unreadDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: Colors.accent,
    marginTop: 6,
  },
  emptyState: { alignItems: 'center', paddingTop: 80, gap: 12, paddingHorizontal: 40 },
  emptyTitle: { color: Colors.textPrimary, fontSize: 18, fontWeight: '600' },
  emptySubtitle: { color: Colors.textSecondary, fontSize: 14, textAlign: 'center', lineHeight: 20 },
});
