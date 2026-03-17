import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { AuthProvider } from '../hooks/useAuth';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <AuthProvider>
        <StatusBar style="light" />
        <Stack screenOptions={{ headerShown: false }}>
          <Stack.Screen name="(auth)" options={{ headerShown: false }} />
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen
            name="post/[id]"
            options={{
              headerShown: true,
              headerStyle: { backgroundColor: '#000' },
              headerTintColor: '#F2F2F2',
              headerTitle: 'Post',
              headerBackTitle: '',
            }}
          />
          <Stack.Screen
            name="profile/[username]"
            options={{ headerShown: false }}
          />
          <Stack.Screen
            name="profile/settings"
            options={{
              headerShown: true,
              headerStyle: { backgroundColor: '#000' },
              headerTintColor: '#F2F2F2',
              headerTitle: 'Settings',
              headerBackTitle: '',
            }}
          />
        </Stack>
      </AuthProvider>
    </GestureHandlerRootView>
  );
}
