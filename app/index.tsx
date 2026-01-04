// app/index.tsx
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useRouter, Redirect } from 'expo-router';
import { supabase } from '../lib/supabase';
import { useAuthProfile } from '../hooks/useAuthProfile';

export default function AuthScreen() {
  const router = useRouter();
  const { session, loading: profileLoading } = useAuthProfile();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [authLoading, setAuthLoading] = useState(false);
  const [isSignUp, setIsSignUp] = useState(false);

  const handleAuth = async () => {
    if (!email || !password) {
      Alert.alert('Missing details', 'Enter email and password.');
      return;
    }

    setAuthLoading(true);

    try {
      if (isSignUp) {
        const { error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;

        Alert.alert(
          'Check your email',
          'We have sent a confirmation link. After confirming, log in.'
        );
        setIsSignUp(false);
      } else {
        const { data, error } =
          await supabase.auth.signInWithPassword({ email, password });

        if (error) throw error;

        if (data.session) {
          // ✅ IMPORTANT: go to /services, not /(tabs)/services
          router.replace('/services');
        }
      }
    } catch (err: any) {
      console.log('Auth error', err);
      Alert.alert(
        'Sign in failed',
        err.message || 'Please check your details and try again.'
      );
    } finally {
      setAuthLoading(false);
    }
  };

  // While we’re checking if a session already exists
  if (profileLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#FFD700" />
      </View>
    );
  }

  // Already logged in → skip login straight into tabs (Services tab)
  if (session) {
    // ✅ Again: NO (tabs) segment here
    return <Redirect href="/services" />;
  }

  // Not logged in: show login / signup form
  return (
    <View style={styles.container}>
      <Text style={styles.logo}>Wantok Service</Text>
      <Text style={styles.subtitle}>Log in to continue</Text>

      <TextInput
        style={styles.input}
        placeholder="you@example.com"
        placeholderTextColor="#6B7280"
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
        keyboardType="email-address"
      />

      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor="#6B7280"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />

      <TouchableOpacity
        style={styles.button}
        onPress={handleAuth}
        disabled={authLoading}
      >
        {authLoading ? (
          <ActivityIndicator color="#FFFFFF" />
        ) : (
          <Text style={styles.buttonText}>
            {isSignUp ? 'Sign up' : 'Log in'}
          </Text>
        )}
      </TouchableOpacity>

      <TouchableOpacity
        onPress={() => setIsSignUp(prev => !prev)}
        style={{ marginTop: 14 }}
      >
        <Text style={styles.link}>
          {isSignUp
            ? 'Already have an account? Log in'
            : "Don't have an account? Sign up"}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    backgroundColor: '#000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    flex: 1,
    backgroundColor: '#000',
    paddingHorizontal: 20,
    paddingTop: 80,
  },
  logo: {
    fontSize: 26,
    fontWeight: '800',
    color: '#FFD700',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 14,
    color: '#E5E7EB',
    marginBottom: 30,
  },
  input: {
    width: '100%',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: '#111827',
    color: '#F9FAFB',
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#1F2937',
  },
  button: {
    marginTop: 10,
    backgroundColor: '#B91C1C',
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 15,
  },
  link: {
    color: '#FACC15',
    fontSize: 13,
    textAlign: 'center',
  },
});
