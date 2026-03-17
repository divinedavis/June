import axios from 'axios';
import * as SecureStore from 'expo-secure-store';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://167.71.170.219:4000';

const api = axios.create({
  baseURL: API_URL,
  timeout: 15000,
});

api.interceptors.request.use(async (config) => {
  const token = await SecureStore.getItemAsync('june_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    const message = error.response?.data?.error || 'Something went wrong';
    return Promise.reject(new Error(message));
  }
);

export default api;

// Auth
export const authAPI = {
  signup: (data: { username: string; email: string; password: string; display_name?: string }) =>
    api.post('/auth/signup', data),
  login: (data: { login: string; password: string }) =>
    api.post('/auth/login', data),
  me: () => api.get('/auth/me'),
  updatePublicKey: (public_key: string) => api.put('/auth/public-key', { public_key }),
};

// Posts
export const postsAPI = {
  create: (data: { content: string; media_url?: string; reply_to_id?: string }) =>
    api.post('/posts', data),
  get: (id: string) => api.get(`/posts/${id}`),
  delete: (id: string) => api.delete(`/posts/${id}`),
  like: (id: string) => api.post(`/posts/${id}/like`),
  unlike: (id: string) => api.delete(`/posts/${id}/like`),
  repost: (id: string) => api.post(`/posts/${id}/repost`),
  unrepost: (id: string) => api.delete(`/posts/${id}/repost`),
  replies: (id: string, cursor?: string) =>
    api.get(`/posts/${id}/replies${cursor ? `?cursor=${cursor}` : ''}`),
};

// Feed
export const feedAPI = {
  forYou: (cursor?: string) =>
    api.get(`/feed/for-you${cursor ? `?cursor=${cursor}` : ''}`),
  following: (cursor?: string) =>
    api.get(`/feed/following${cursor ? `?cursor=${cursor}` : ''}`),
};

// Users
export const usersAPI = {
  get: (username: string) => api.get(`/users/${username}`),
  posts: (username: string, cursor?: string) =>
    api.get(`/users/${username}/posts${cursor ? `?cursor=${cursor}` : ''}`),
  follow: (username: string) => api.post(`/users/${username}/follow`),
  unfollow: (username: string) => api.delete(`/users/${username}/follow`),
  followers: (username: string) => api.get(`/users/${username}/followers`),
  following: (username: string) => api.get(`/users/${username}/following`),
  updateProfile: (data: { display_name?: string; bio?: string; avatar_url?: string; is_public?: boolean }) =>
    api.put('/users/me', data),
};

// DMs
export const dmsAPI = {
  conversations: () => api.get('/dms/conversations'),
  startConversation: (username: string) => api.post('/dms/conversations', { username }),
  messages: (conversationId: string, cursor?: string) =>
    api.get(`/dms/conversations/${conversationId}/messages${cursor ? `?cursor=${cursor}` : ''}`),
  sendMessage: (conversationId: string, data: { encrypted_content: string; nonce: string }) =>
    api.post(`/dms/conversations/${conversationId}/messages`, data),
};

// Notifications
export const notificationsAPI = {
  list: (cursor?: string) =>
    api.get(`/notifications${cursor ? `?cursor=${cursor}` : ''}`),
  unreadCount: () => api.get('/notifications/unread-count'),
  markAllRead: () => api.patch('/notifications/read'),
};

// Search
export const searchAPI = {
  search: (q: string, type?: string) =>
    api.get(`/search?q=${encodeURIComponent(q)}${type ? `&type=${type}` : ''}`),
  trending: () => api.get('/search/trending'),
};
