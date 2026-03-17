import React, { useState } from 'react';
import {
  View, Text, StyleSheet, TouchableOpacity, TextInput,
  Alert, ScrollView, Switch, ActivityIndicator
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/colors';
import { useAuth } from '../../hooks/useAuth';
import { usersAPI } from '../../services/api';

export default function SettingsScreen() {
  const { user, logout, updateUser } = useAuth();
  const [displayName, setDisplayName] = useState(user?.display_name || '');
  const [bio, setBio] = useState(user?.bio || '');
  const [isPublic, setIsPublic] = useState(user?.is_public ?? true);
  const [saving, setSaving] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      const { user: updatedUser } = await usersAPI.updateProfile({
        display_name: displayName.trim(),
        bio: bio.trim(),
        is_public: isPublic,
      }) as any;
      updateUser(updatedUser);
      Alert.alert('Saved', 'Your profile has been updated');
    } catch (err: any) {
      Alert.alert('Error', err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Sign Out',
          style: 'destructive',
          onPress: async () => {
            setLoggingOut(true);
            await logout();
            router.replace('/(auth)/login');
          },
        },
      ]
    );
  };

  const SettingRow = ({
    icon, title, value, onPress, destructive = false, rightElement
  }: {
    icon: string;
    title: string;
    value?: string;
    onPress?: () => void;
    destructive?: boolean;
    rightElement?: React.ReactNode;
  }) => (
    <TouchableOpacity
      style={styles.settingRow}
      onPress={onPress}
      disabled={!onPress}
      activeOpacity={onPress ? 0.7 : 1}
    >
      <View style={styles.settingLeft}>
        <Ionicons name={icon as any} size={20} color={destructive ? Colors.error : Colors.textSecondary} />
        <Text style={[styles.settingTitle, destructive && { color: Colors.error }]}>{title}</Text>
      </View>
      {value && <Text style={styles.settingValue}>{value}</Text>}
      {rightElement}
      {onPress && !rightElement && (
        <Ionicons name="chevron-forward" size={16} color={Colors.textTertiary} />
      )}
    </TouchableOpacity>
  );

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Account info */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Account</Text>
        <SettingRow icon="person-outline" title="Username" value={`@${user?.username}`} />
        <SettingRow icon="mail-outline" title="Email" value={user?.email} />
      </View>

      {/* Profile editing */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Profile</Text>

        <View style={styles.inputGroup}>
          <Text style={styles.inputLabel}>Display Name</Text>
          <TextInput
            style={styles.input}
            value={displayName}
            onChangeText={setDisplayName}
            placeholder="Your display name"
            placeholderTextColor={Colors.textPlaceholder}
            selectionColor={Colors.accent}
            maxLength={50}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.inputLabel}>Bio</Text>
          <TextInput
            style={[styles.input, styles.bioInput]}
            value={bio}
            onChangeText={setBio}
            placeholder="Tell people about yourself"
            placeholderTextColor={Colors.textPlaceholder}
            multiline
            selectionColor={Colors.accent}
            maxLength={160}
          />
        </View>

        <TouchableOpacity
          style={[styles.saveBtn, saving && styles.saveBtnDisabled]}
          onPress={handleSave}
          disabled={saving}
          activeOpacity={0.85}
        >
          {saving ? (
            <ActivityIndicator color="#000" size="small" />
          ) : (
            <Text style={styles.saveBtnText}>Save Changes</Text>
          )}
        </TouchableOpacity>
      </View>

      {/* Privacy */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Privacy</Text>

        <View style={styles.settingRow}>
          <View style={styles.settingLeft}>
            <Ionicons name="globe-outline" size={20} color={Colors.textSecondary} />
            <View>
              <Text style={styles.settingTitle}>Public Account</Text>
              <Text style={styles.settingSubtitle}>
                {isPublic ? 'Anyone can see your posts' : 'Only followers can see your posts'}
              </Text>
            </View>
          </View>
          <Switch
            value={isPublic}
            onValueChange={setIsPublic}
            trackColor={{ false: Colors.border, true: Colors.accent }}
            thumbColor="#fff"
          />
        </View>
      </View>

      {/* About */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>About</Text>
        <SettingRow icon="information-circle-outline" title="Version" value="1.0.0" />
        <SettingRow icon="shield-outline" title="Privacy Policy" onPress={() => {}} />
        <SettingRow icon="document-text-outline" title="Terms of Service" onPress={() => {}} />
      </View>

      {/* Sign out */}
      <View style={[styles.section, styles.lastSection]}>
        <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout} disabled={loggingOut}>
          {loggingOut ? (
            <ActivityIndicator color={Colors.error} size="small" />
          ) : (
            <>
              <Ionicons name="log-out-outline" size={20} color={Colors.error} />
              <Text style={styles.logoutText}>Sign Out</Text>
            </>
          )}
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.background },
  section: {
    marginTop: 24,
    marginHorizontal: 16,
    backgroundColor: Colors.surface,
    borderRadius: 16,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: Colors.border,
  },
  lastSection: { marginBottom: 48 },
  sectionTitle: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 8,
  },
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: Colors.border,
  },
  settingLeft: { flexDirection: 'row', alignItems: 'center', gap: 12, flex: 1 },
  settingTitle: { color: Colors.textPrimary, fontSize: 16 },
  settingSubtitle: { color: Colors.textSecondary, fontSize: 13, marginTop: 2 },
  settingValue: { color: Colors.textSecondary, fontSize: 15 },
  inputGroup: { paddingHorizontal: 16, paddingVertical: 12, borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: Colors.border },
  inputLabel: {
    color: Colors.textSecondary,
    fontSize: 12,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: 8,
  },
  input: {
    backgroundColor: Colors.surfaceElevated,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    color: Colors.textPrimary,
    fontSize: 16,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  bioInput: { height: 80, textAlignVertical: 'top' },
  saveBtn: {
    backgroundColor: Colors.accent,
    borderRadius: 50,
    paddingVertical: 14,
    alignItems: 'center',
    margin: 16,
  },
  saveBtnDisabled: { opacity: 0.6 },
  saveBtnText: { color: '#000', fontSize: 15, fontWeight: '700' },
  logoutBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    gap: 8,
  },
  logoutText: { color: Colors.error, fontSize: 16, fontWeight: '600' },
});
