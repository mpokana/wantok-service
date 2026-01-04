import React from 'react';
import { TouchableOpacity, Text, StyleSheet, Alert } from 'react-native';
import { useRouter } from 'expo-router';
import { supabase } from '../lib/supabase';

export default function SignOutButton() {
  const router = useRouter();

  const handleSignOut = async () => {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) {
        console.log('Sign out error', error);
        Alert.alert('Error', error.message || 'Could not sign out.');
        return;
      }

      // RootLayout will show login when session is null
      router.replace('/');
    } catch (err: any) {
      console.log('Sign out error', err);
      Alert.alert('Error', 'Something went wrong signing out.');
    }
  };

  return (
    <TouchableOpacity style={styles.button} onPress={handleSignOut}>
      <Text style={styles.text}>Sign out</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    marginRight: 12,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: '#FACC15',
  },
  text: {
    color: '#FACC15',
    fontSize: 11,
    fontWeight: '600',
  },
});
