import React, { useState } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  KeyboardAvoidingView, Platform, ScrollView, Alert, ActivityIndicator
} from 'react-native';
import { router } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '../../constants/colors';
import { useAuth } from '../../hooks/useAuth';
import FalconLogo from '../../components/FalconLogo';

export default function SignupScreen() {
  const { signup } = useAuth();
  const [step, setStep] = useState(1);
  const [displayName, setDisplayName] = useState('');
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [usernameError, setUsernameError] = useState('');

  const validateUsername = (value: string) => {
    if (!/^[a-zA-Z0-9_]{3,30}$/.test(value)) {
      setUsernameError('3-30 characters, letters, numbers, and _ only');
    } else {
      setUsernameError('');
    }
  };

  const handleNextStep = () => {
    if (step === 1) {
      if (!displayName.trim()) return Alert.alert('Error', 'Please enter your name');
      if (!username.trim() || usernameError) return Alert.alert('Error', 'Please enter a valid username');
      setStep(2);
    }
  };

  const handleSignup = async () => {
    if (!email.trim()) return Alert.alert('Error', 'Please enter your email');
    if (password.length < 8) return Alert.alert('Error', 'Password must be at least 8 characters');
    if (password !== confirmPassword) return Alert.alert('Error', 'Passwords do not match');

    setLoading(true);
    try {
      await signup({
        username: username.trim().toLowerCase(),
        email: email.trim().toLowerCase(),
        password,
        display_name: displayName.trim(),
      });
      router.replace('/(tabs)');
    } catch (err: any) {
      Alert.alert('Sign Up Failed', err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.safe}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : 'height'} style={styles.flex}>
        <ScrollView contentContainerStyle={styles.container} keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false}>

          {/* Back button */}
          <TouchableOpacity
            style={styles.backBtn}
            onPress={step === 1 ? () => router.back() : () => setStep(1)}
          >
            <Ionicons name="chevron-back" size={24} color={Colors.textPrimary} />
          </TouchableOpacity>

          {/* Logo */}
          <View style={styles.logoSection}>
            <FalconLogo size={56} color={Colors.accent} />
          </View>

          <Text style={styles.title}>
            {step === 1 ? 'Create your account' : 'Complete sign up'}
          </Text>

          {/* Step indicator */}
          <View style={styles.steps}>
            <View style={[styles.stepDot, styles.stepDotActive]} />
            <View style={styles.stepLine} />
            <View style={[styles.stepDot, step === 2 && styles.stepDotActive]} />
          </View>

          {step === 1 ? (
            <>
              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Name</Text>
                <TextInput
                  style={styles.input}
                  value={displayName}
                  onChangeText={setDisplayName}
                  placeholder="Your display name"
                  placeholderTextColor={Colors.textPlaceholder}
                  autoCorrect={false}
                  returnKeyType="next"
                  selectionColor={Colors.accent}
                />
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Username</Text>
                <TextInput
                  style={[styles.input, usernameError ? styles.inputError : null]}
                  value={username}
                  onChangeText={(val) => {
                    setUsername(val);
                    validateUsername(val);
                  }}
                  placeholder="your_username"
                  placeholderTextColor={Colors.textPlaceholder}
                  autoCapitalize="none"
                  autoCorrect={false}
                  returnKeyType="done"
                  selectionColor={Colors.accent}
                />
                {usernameError ? (
                  <Text style={styles.errorText}>{usernameError}</Text>
                ) : username.length > 0 ? (
                  <Text style={styles.helperText}>@{username.toLowerCase()}</Text>
                ) : null}
              </View>

              <TouchableOpacity style={styles.primaryBtn} onPress={handleNextStep} activeOpacity={0.85}>
                <Text style={styles.primaryBtnText}>Continue</Text>
              </TouchableOpacity>
            </>
          ) : (
            <>
              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Email</Text>
                <TextInput
                  style={styles.input}
                  value={email}
                  onChangeText={setEmail}
                  placeholder="you@example.com"
                  placeholderTextColor={Colors.textPlaceholder}
                  autoCapitalize="none"
                  autoCorrect={false}
                  keyboardType="email-address"
                  returnKeyType="next"
                  selectionColor={Colors.accent}
                />
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Password</Text>
                <View style={styles.passwordRow}>
                  <TextInput
                    style={[styles.input, styles.passwordInput]}
                    value={password}
                    onChangeText={setPassword}
                    placeholder="At least 8 characters"
                    placeholderTextColor={Colors.textPlaceholder}
                    secureTextEntry={!showPassword}
                    returnKeyType="next"
                    selectionColor={Colors.accent}
                  />
                  <TouchableOpacity style={styles.showPasswordBtn} onPress={() => setShowPassword(!showPassword)}>
                    <Text style={styles.showPasswordText}>{showPassword ? 'Hide' : 'Show'}</Text>
                  </TouchableOpacity>
                </View>
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Confirm Password</Text>
                <TextInput
                  style={styles.input}
                  value={confirmPassword}
                  onChangeText={setConfirmPassword}
                  placeholder="Repeat password"
                  placeholderTextColor={Colors.textPlaceholder}
                  secureTextEntry={!showPassword}
                  returnKeyType="done"
                  onSubmitEditing={handleSignup}
                  selectionColor={Colors.accent}
                />
              </View>

              <Text style={styles.disclaimer}>
                By signing up, you agree to our Terms of Service and Privacy Policy.
              </Text>

              <TouchableOpacity
                style={[styles.primaryBtn, loading && styles.primaryBtnDisabled]}
                onPress={handleSignup}
                disabled={loading}
                activeOpacity={0.85}
              >
                {loading ? (
                  <ActivityIndicator color="#000" size="small" />
                ) : (
                  <Text style={styles.primaryBtnText}>Create Account</Text>
                )}
              </TouchableOpacity>
            </>
          )}

          <View style={styles.loginRow}>
            <Text style={styles.loginText}>Already have an account? </Text>
            <TouchableOpacity onPress={() => router.replace('/(auth)/login')}>
              <Text style={styles.loginLink}>Sign In</Text>
            </TouchableOpacity>
          </View>

        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: Colors.background },
  flex: { flex: 1 },
  container: { flexGrow: 1, paddingHorizontal: 32, paddingBottom: 40 },
  backBtn: { marginTop: 8, marginBottom: 8, width: 40 },
  logoSection: { alignItems: 'center', marginBottom: 24 },
  title: {
    color: Colors.textPrimary,
    fontSize: 24,
    fontWeight: '700',
    marginBottom: 20,
    letterSpacing: -0.3,
  },
  steps: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 32,
  },
  stepDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: Colors.border,
  },
  stepDotActive: { backgroundColor: Colors.accent },
  stepLine: {
    flex: 1,
    height: 2,
    backgroundColor: Colors.border,
    marginHorizontal: 8,
  },
  inputContainer: { marginBottom: 20 },
  inputLabel: {
    color: Colors.textSecondary,
    fontSize: 13,
    fontWeight: '500',
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  input: {
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    color: Colors.textPrimary,
    fontSize: 16,
  },
  inputError: { borderColor: Colors.error },
  errorText: { color: Colors.error, fontSize: 12, marginTop: 6 },
  helperText: { color: Colors.textSecondary, fontSize: 13, marginTop: 6 },
  passwordRow: { position: 'relative' },
  passwordInput: { paddingRight: 60 },
  showPasswordBtn: {
    position: 'absolute',
    right: 16,
    top: 0,
    bottom: 0,
    justifyContent: 'center',
  },
  showPasswordText: { color: Colors.accent, fontSize: 14, fontWeight: '500' },
  primaryBtn: {
    backgroundColor: Colors.accent,
    borderRadius: 50,
    paddingVertical: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  primaryBtnDisabled: { opacity: 0.6 },
  primaryBtnText: { color: '#000', fontSize: 16, fontWeight: '700' },
  disclaimer: {
    color: Colors.textTertiary,
    fontSize: 12,
    lineHeight: 18,
    marginBottom: 16,
    textAlign: 'center',
  },
  loginRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 24,
  },
  loginText: { color: Colors.textSecondary, fontSize: 14 },
  loginLink: { color: Colors.accent, fontSize: 14, fontWeight: '600' },
});
