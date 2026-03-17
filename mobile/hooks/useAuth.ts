import { useState, useEffect, createContext, useContext } from 'react';
import * as SecureStore from 'expo-secure-store';
import { authAPI, usersAPI } from '../services/api';
import { getOrCreateKeyPair } from '../services/encryption';

interface User {
  id: string;
  username: string;
  email: string;
  display_name: string;
  bio?: string;
  avatar_url?: string;
  is_public: boolean;
  follower_count: number;
  following_count: number;
  post_count: number;
  public_key?: string;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (login: string, password: string) => Promise<void>;
  signup: (data: { username: string; email: string; password: string; display_name?: string }) => Promise<void>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
  updateUser: (updates: Partial<User>) => void;
}

import React from 'react';

export const AuthContext = createContext<AuthContextType>({} as AuthContextType);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStoredAuth();
  }, []);

  const loadStoredAuth = async () => {
    try {
      const storedToken = await SecureStore.getItemAsync('june_token');
      if (storedToken) {
        setToken(storedToken);
        const { user } = await authAPI.me() as any;
        setUser(user);
      }
    } catch {
      await SecureStore.deleteItemAsync('june_token');
    } finally {
      setLoading(false);
    }
  };

  const initializeEncryption = async () => {
    try {
      const { publicKey } = await getOrCreateKeyPair();
      await authAPI.updatePublicKey(publicKey);
    } catch {
      // Non-blocking
    }
  };

  const login = async (loginInput: string, password: string) => {
    const { user, token } = await authAPI.login({ login: loginInput, password }) as any;
    await SecureStore.setItemAsync('june_token', token);
    setToken(token);
    setUser(user);
    await initializeEncryption();
  };

  const signup = async (data: { username: string; email: string; password: string; display_name?: string }) => {
    const { user, token } = await authAPI.signup(data) as any;
    await SecureStore.setItemAsync('june_token', token);
    setToken(token);
    setUser(user);
    await initializeEncryption();
  };

  const logout = async () => {
    await SecureStore.deleteItemAsync('june_token');
    setToken(null);
    setUser(null);
  };

  const refreshUser = async () => {
    const { user } = await authAPI.me() as any;
    setUser(user);
  };

  const updateUser = (updates: Partial<User>) => {
    setUser(prev => prev ? { ...prev, ...updates } : null);
  };

  return React.createElement(AuthContext.Provider, {
    value: { user, token, loading, login, signup, logout, refreshUser, updateUser }
  }, children);
};

export const useAuth = () => useContext(AuthContext);
