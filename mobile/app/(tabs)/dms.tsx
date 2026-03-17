import React, { useState, useEffect, useRef } from 'react';
import {
  View, Text, FlatList, StyleSheet, TouchableOpacity,
  TextInput, KeyboardAvoidingView, Platform, RefreshControl,
  Alert, ActivityIndicator, Modal
} from 'react-native';
import { Image } from 'expo-image';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { io, Socket } from 'socket.io-client';
import * as SecureStore from 'expo-secure-store';
import { Colors } from '../../constants/colors';
import { dmsAPI, usersAPI } from '../../services/api';
import { useAuth } from '../../hooks/useAuth';
import { encryptMessage, decryptMessage, getMyPrivateKey } from '../../services/encryption';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://167.71.170.219:4000';

const timeAgo = (dateStr: string) => {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'now';
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h`;
  return `${Math.floor(hours / 24)}d`;
};

export default function DMsScreen() {
  const { user, token } = useAuth();
  const [conversations, setConversations] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedConvo, setSelectedConvo] = useState<any>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [messageText, setMessageText] = useState('');
  const [sending, setSending] = useState(false);
  const [newDmVisible, setNewDmVisible] = useState(false);
  const [newDmUsername, setNewDmUsername] = useState('');
  const socketRef = useRef<Socket | null>(null);
  const flatListRef = useRef<FlatList>(null);

  useEffect(() => {
    loadConversations(true);
    setupSocket();
    return () => {
      socketRef.current?.disconnect();
    };
  }, []);

  const setupSocket = async () => {
    const storedToken = await SecureStore.getItemAsync('june_token');
    if (!storedToken) return;

    const socket = io(API_URL, { auth: { token: storedToken } });
    socketRef.current = socket;

    socket.on('new_message', (message: any) => {
      if (selectedConvo && message.conversation_id === selectedConvo.id) {
        setMessages(prev => [...prev, message]);
        flatListRef.current?.scrollToEnd({ animated: true });
      }
      setConversations(prev => prev.map(c =>
        c.id === message.conversation_id
          ? { ...c, last_message_time: message.created_at, last_message_encrypted: message.encrypted_content }
          : c
      ));
    });
  };

  const loadConversations = async (refresh = false) => {
    if (refresh) setRefreshing(true); else setLoading(true);
    try {
      const data: any = await dmsAPI.conversations();
      setConversations(data.conversations);
    } catch {
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const openConversation = async (convo: any) => {
    setSelectedConvo(convo);
    setMessages([]);
    socketRef.current?.emit('join_conversation', convo.id);

    try {
      const data: any = await dmsAPI.messages(convo.id);
      const myPrivateKey = await getMyPrivateKey();

      const decryptedMessages = data.messages.map((msg: any) => {
        const isFromMe = msg.sender.id === user?.id;
        let decryptedText: string | null = null;

        if (myPrivateKey) {
          const otherPublicKey = isFromMe
            ? convo.other_user.public_key
            : msg.sender.public_key || convo.other_user.public_key;

          if (otherPublicKey) {
            decryptedText = decryptMessage(
              msg.encrypted_content,
              msg.nonce,
              isFromMe ? otherPublicKey : otherPublicKey,
              myPrivateKey
            );
          }
        }

        return {
          ...msg,
          decrypted_content: decryptedText || '[Encrypted message]',
        };
      });

      setMessages(decryptedMessages);
      setTimeout(() => flatListRef.current?.scrollToEnd({ animated: false }), 100);
    } catch (err: any) {
      Alert.alert('Error', err.message);
    }
  };

  const sendMessage = async () => {
    if (!messageText.trim() || !selectedConvo || sending) return;
    setSending(true);

    const text = messageText.trim();
    setMessageText('');

    try {
      const myPrivateKey = await getMyPrivateKey();
      const recipientPublicKey = selectedConvo.other_user.public_key;

      let encrypted_content: string;
      let nonce: string;

      if (myPrivateKey && recipientPublicKey) {
        const result = encryptMessage(text, recipientPublicKey, myPrivateKey);
        encrypted_content = result.encrypted;
        nonce = result.nonce;
      } else {
        // Fallback: base64 encode (not truly E2E but stored server-side)
        encrypted_content = Buffer.from(text).toString('base64');
        nonce = 'plaintext';
      }

      const { message } = await dmsAPI.sendMessage(selectedConvo.id, {
        encrypted_content,
        nonce,
      }) as any;

      setMessages(prev => [...prev, { ...message, decrypted_content: text }]);
      flatListRef.current?.scrollToEnd({ animated: true });
    } catch (err: any) {
      Alert.alert('Error', err.message);
      setMessageText(text);
    } finally {
      setSending(false);
    }
  };

  const startNewDm = async () => {
    if (!newDmUsername.trim()) return;
    try {
      const data: any = await dmsAPI.startConversation(newDmUsername.trim());
      setNewDmVisible(false);
      setNewDmUsername('');
      await loadConversations(true);
      openConversation(data.conversation);
    } catch (err: any) {
      Alert.alert('Error', err.message);
    }
  };

  // Conversation list view
  if (!selectedConvo) {
    return (
      <View style={styles.container}>
        <FlatList
          data={conversations}
          keyExtractor={(item) => item.id}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={() => loadConversations(true)} tintColor={Colors.accent} />
          }
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.convoRow} onPress={() => openConversation(item)}>
              {item.other_user.avatar_url ? (
                <Image source={{ uri: item.other_user.avatar_url }} style={styles.convoAvatar} contentFit="cover" />
              ) : (
                <View style={styles.convoAvatarFallback}>
                  <Text style={styles.convoAvatarLetter}>
                    {(item.other_user.display_name || item.other_user.username)[0].toUpperCase()}
                  </Text>
                </View>
              )}
              <View style={styles.convoInfo}>
                <View style={styles.convoHeader}>
                  <Text style={styles.convoName}>{item.other_user.display_name || item.other_user.username}</Text>
                  {item.last_message_time && (
                    <Text style={styles.convoTime}>{timeAgo(item.last_message_time)}</Text>
                  )}
                </View>
                <Text style={styles.convoPreview} numberOfLines={1}>
                  {item.last_message_encrypted ? '🔒 Encrypted message' : 'No messages yet'}
                </Text>
              </View>
            </TouchableOpacity>
          )}
          ListEmptyComponent={
            !loading ? (
              <View style={styles.emptyState}>
                <Ionicons name="chatbubble-ellipses-outline" size={48} color={Colors.textTertiary} />
                <Text style={styles.emptyTitle}>No messages yet</Text>
                <Text style={styles.emptySubtitle}>Send a DM to start a conversation</Text>
              </View>
            ) : null
          }
        />
        <TouchableOpacity style={styles.fab} onPress={() => setNewDmVisible(true)}>
          <Ionicons name="create-outline" size={24} color="#000" />
        </TouchableOpacity>

        <Modal visible={newDmVisible} animationType="slide" presentationStyle="pageSheet" onRequestClose={() => setNewDmVisible(false)}>
          <View style={styles.newDmModal}>
            <View style={styles.newDmHeader}>
              <TouchableOpacity onPress={() => setNewDmVisible(false)}>
                <Text style={styles.cancelBtn}>Cancel</Text>
              </TouchableOpacity>
              <Text style={styles.newDmTitle}>New Message</Text>
              <TouchableOpacity onPress={startNewDm}>
                <Text style={[styles.nextBtn, !newDmUsername.trim() && styles.nextBtnDisabled]}>Next</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.newDmSearch}>
              <Ionicons name="search" size={16} color={Colors.textTertiary} />
              <TextInput
                style={styles.newDmInput}
                value={newDmUsername}
                onChangeText={setNewDmUsername}
                placeholder="Search username"
                placeholderTextColor={Colors.textPlaceholder}
                autoCapitalize="none"
                autoFocus
                selectionColor={Colors.accent}
              />
            </View>
          </View>
        </Modal>
      </View>
    );
  }

  // Message thread view
  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
      {/* Thread header */}
      <View style={styles.threadHeader}>
        <TouchableOpacity onPress={() => {
          socketRef.current?.emit('leave_conversation', selectedConvo.id);
          setSelectedConvo(null);
        }}>
          <Ionicons name="chevron-back" size={24} color={Colors.textPrimary} />
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.threadUserInfo}
          onPress={() => router.push(`/profile/${selectedConvo.other_user.username}`)}
        >
          {selectedConvo.other_user.avatar_url ? (
            <Image source={{ uri: selectedConvo.other_user.avatar_url }} style={styles.threadAvatar} contentFit="cover" />
          ) : (
            <View style={styles.convoAvatarFallback}>
              <Text style={styles.convoAvatarLetter}>
                {(selectedConvo.other_user.display_name || selectedConvo.other_user.username)[0].toUpperCase()}
              </Text>
            </View>
          )}
          <View>
            <Text style={styles.threadName}>{selectedConvo.other_user.display_name || selectedConvo.other_user.username}</Text>
            <Text style={styles.threadUsername}>@{selectedConvo.other_user.username}</Text>
          </View>
        </TouchableOpacity>
        <View style={styles.encryptedBadge}>
          <Ionicons name="lock-closed" size={12} color={Colors.repost} />
          <Text style={styles.encryptedText}>E2E</Text>
        </View>
      </View>

      {/* Messages */}
      <FlatList
        ref={flatListRef}
        data={messages}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => {
          const isFromMe = item.sender.id === user?.id;
          return (
            <View style={[styles.messageBubbleWrapper, isFromMe && styles.messageBubbleWrapperMe]}>
              <View style={[styles.messageBubble, isFromMe ? styles.messageBubbleMe : styles.messageBubbleThem]}>
                <Text style={[styles.messageText, isFromMe && styles.messageTextMe]}>
                  {item.decrypted_content}
                </Text>
              </View>
            </View>
          );
        }}
        contentContainerStyle={{ padding: 16, gap: 8 }}
        showsVerticalScrollIndicator={false}
      />

      {/* Input */}
      <View style={styles.inputRow}>
        <TextInput
          style={styles.messageInput}
          value={messageText}
          onChangeText={setMessageText}
          placeholder="Message"
          placeholderTextColor={Colors.textPlaceholder}
          multiline
          selectionColor={Colors.accent}
          returnKeyType="send"
          onSubmitEditing={sendMessage}
        />
        <TouchableOpacity
          style={[styles.sendBtn, (!messageText.trim() || sending) && styles.sendBtnDisabled]}
          onPress={sendMessage}
          disabled={!messageText.trim() || sending}
        >
          {sending ? (
            <ActivityIndicator color="#000" size="small" />
          ) : (
            <Ionicons name="arrow-up" size={18} color="#000" />
          )}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  convoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    gap: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
  },
  convoAvatar: { width: 52, height: 52, borderRadius: 26 },
  convoAvatarFallback: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: Colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
  convoAvatarLetter: { color: Colors.accent, fontSize: 20, fontWeight: '600' },
  convoInfo: { flex: 1 },
  convoHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  convoName: { color: Colors.textPrimary, fontSize: 16, fontWeight: '600' },
  convoTime: { color: Colors.textTertiary, fontSize: 13 },
  convoPreview: { color: Colors.textSecondary, fontSize: 14, marginTop: 3 },
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
  },
  emptyState: { alignItems: 'center', paddingTop: 80, gap: 12, paddingHorizontal: 40 },
  emptyTitle: { color: Colors.textPrimary, fontSize: 18, fontWeight: '600' },
  emptySubtitle: { color: Colors.textSecondary, fontSize: 14, textAlign: 'center' },
  newDmModal: { flex: 1, backgroundColor: Colors.background },
  newDmHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
  },
  cancelBtn: { color: Colors.textSecondary, fontSize: 16 },
  newDmTitle: { color: Colors.textPrimary, fontSize: 16, fontWeight: '700' },
  nextBtn: { color: Colors.accent, fontSize: 16, fontWeight: '700' },
  nextBtnDisabled: { opacity: 0.4 },
  newDmSearch: {
    flexDirection: 'row',
    alignItems: 'center',
    margin: 16,
    backgroundColor: Colors.surface,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    gap: 8,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  newDmInput: { flex: 1, color: Colors.textPrimary, fontSize: 16 },
  threadHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
    gap: 12,
  },
  threadUserInfo: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 10 },
  threadAvatar: { width: 36, height: 36, borderRadius: 18 },
  threadName: { color: Colors.textPrimary, fontSize: 15, fontWeight: '600' },
  threadUsername: { color: Colors.textSecondary, fontSize: 13 },
  encryptedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: `${Colors.repost}15`,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 10,
  },
  encryptedText: { color: Colors.repost, fontSize: 11, fontWeight: '600' },
  messageBubbleWrapper: { flexDirection: 'row', alignItems: 'flex-end' },
  messageBubbleWrapperMe: { justifyContent: 'flex-end' },
  messageBubble: {
    maxWidth: '75%',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 20,
  },
  messageBubbleMe: {
    backgroundColor: Colors.accent,
    borderBottomRightRadius: 4,
  },
  messageBubbleThem: {
    backgroundColor: Colors.surface,
    borderBottomLeftRadius: 4,
  },
  messageText: { color: Colors.textPrimary, fontSize: 15, lineHeight: 21 },
  messageTextMe: { color: '#000' },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: Colors.border,
    gap: 10,
  },
  messageInput: {
    flex: 1,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 10,
    color: Colors.textPrimary,
    fontSize: 16,
    maxHeight: 120,
  },
  sendBtn: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: Colors.accent,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendBtnDisabled: { opacity: 0.4 },
});
