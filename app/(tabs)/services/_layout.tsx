import React from 'react';
import { Stack } from 'expo-router';
import SignOutButton from '../../../components/SignOutButton';

export default function ServicesLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: '#000' },
        headerTintColor: '#FACC15',
        headerTitleStyle: {
          fontWeight: '600',
        },
        contentStyle: { backgroundColor: '#000' },
        headerRight: () => <SignOutButton />,
      }}
    />
  );
}
