// app/(tabs)/_layout.tsx
import { Redirect, Tabs } from 'expo-router';
import React from 'react';
import { ActivityIndicator, View } from 'react-native';
import { useAuthProfile } from '../../hooks/useAuthProfile';

export default function TabsLayout() {
  const { session, profile, hasRole, loading } = useAuthProfile();

  if (loading) {
    return (
      <View
        style={{
          flex: 1,
          backgroundColor: '#000',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <ActivityIndicator size="large" color="#FFD700" />
      </View>
    );
  }

  if (!session) {
    return <Redirect href="/" />;
  }

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#FFD700',
        tabBarInactiveTintColor: '#9CA3AF',
        tabBarStyle: {
          backgroundColor: '#000',
          borderTopColor: '#111',
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '600',
        },
      }}
    >
      {/* Main customer-facing services tab (maps to app/(tabs)/services/index.tsx or folder) */}
      <Tabs.Screen
        name="services"
        options={{ title: 'Services' }}
      />

      {/* Apply tab visible to everyone */}
      <Tabs.Screen
        name="apply"
        options={{ title: 'apply' }}
      />

      {/* Explore / marketing / listings */}
      <Tabs.Screen
        name="explore"
        options={{ title: 'explore' }}
      />

      {/* Provider tab for approved provider RBAC or legacy provider flag */}
      {(profile?.is_provider || hasRole('provider')) && (
        <Tabs.Screen
          name="provider"
          options={{ title: 'provider' }}
        />
      )}

      {/* Admin tab for RBAC administrators or legacy admin flag */}
      {(profile?.is_admin || hasRole('admin')) && (
        <Tabs.Screen
          name="admin"
          options={{ title: 'admin' }}
        />
      )}

      {/* Account tab for everyone */}
      <Tabs.Screen
        name="account"
        options={{ title: 'Account' }}
      />
    </Tabs>
  );
}
