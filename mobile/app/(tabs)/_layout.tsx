import { Tabs, router } from 'expo-router';
import { View, StyleSheet, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/colors';
import { useAuth } from '../../hooks/useAuth';
import { Image } from 'expo-image';
import { useEffect } from 'react';

function HeaderLeft() {
  const { user } = useAuth();

  const navigateToProfile = () => {
    if (user) router.push(`/profile/${user.username}`);
  };

  return (
    <TouchableOpacity onPress={navigateToProfile} style={{ marginLeft: 16 }}>
      {user?.avatar_url ? (
        <Image
          source={{ uri: user.avatar_url }}
          style={{ width: 32, height: 32, borderRadius: 16 }}
          contentFit="cover"
        />
      ) : (
        <View style={styles.avatarFallback}>
          <Ionicons name="person" size={16} color={Colors.accent} />
        </View>
      )}
    </TouchableOpacity>
  );
}

export default function TabsLayout() {
  const { user } = useAuth();

  useEffect(() => {
    if (!user) {
      router.replace('/(auth)/login');
    }
  }, [user]);

  if (!user) return null;

  return (
    <Tabs
      screenOptions={{
        tabBarStyle: styles.tabBar,
        tabBarActiveTintColor: Colors.tabActive,
        tabBarInactiveTintColor: Colors.tabInactive,
        tabBarShowLabel: false,
        headerStyle: styles.header,
        headerTintColor: Colors.textPrimary,
        headerTitleStyle: styles.headerTitle,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          headerTitle: 'June',
          headerTitleStyle: [styles.headerTitle, { color: Colors.accent, fontSize: 22, fontWeight: '800' }],
          headerLeft: () => <HeaderLeft />,
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'home' : 'home-outline'} size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="search"
        options={{
          headerTitle: 'Explore',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'search' : 'search-outline'} size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="alerts"
        options={{
          headerTitle: 'Notifications',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'notifications' : 'notifications-outline'} size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="dms"
        options={{
          headerTitle: 'Messages',
          tabBarIcon: ({ color, size, focused }) => (
            <Ionicons name={focused ? 'chatbubble-ellipses' : 'chatbubble-ellipses-outline'} size={size} color={color} />
          ),
        }}
      />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    backgroundColor: Colors.tabBarBackground,
    borderTopColor: Colors.tabBarBorder,
    borderTopWidth: StyleSheet.hairlineWidth,
    height: 84,
    paddingBottom: 28,
    paddingTop: 10,
  },
  header: {
    backgroundColor: Colors.background,
    shadowColor: 'transparent',
    elevation: 0,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: Colors.border,
  },
  headerTitle: {
    color: Colors.textPrimary,
    fontSize: 17,
    fontWeight: '600',
  },
  avatarFallback: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: Colors.surfaceElevated,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
