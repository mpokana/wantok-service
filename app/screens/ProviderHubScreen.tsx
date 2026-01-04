import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  Platform,
} from 'react-native';
import * as Location from 'expo-location';
import { supabase } from '../../lib/supabase';
import { useAuthProfile } from '../../hooks/useAuthProfile';

type LocationSubscription = Location.LocationSubscription | null;

export default function ProviderHubScreen() {
  const { providerAccount, loading } = useAuthProfile();
  const [isOnline, setIsOnline] = useState(false);
  const [updating, setUpdating] = useState(false);
  const locationSubRef = useRef<LocationSubscription>(null);

  // Safety: if provider becomes inactive while screen is open
  useEffect(() => {
    if (!providerAccount || !providerAccount.is_active) {
      setIsOnline(false);
      stopLocationUpdates();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [providerAccount?.is_active]);

  const startLocationUpdates = async () => {
    if (!providerAccount || !providerAccount.is_active) {
      Alert.alert(
        'Not approved yet',
        'Your provider account is not active. Please wait for Wantok Service Support to approve your application.'
      );
      return;
    }

    const isDriver = !!providerAccount.service_type?.includes?.('driver');
    if (!isDriver) {
      Alert.alert(
        'No driver role',
        'Your account is approved, but not as a driver. Please contact Wantok Service Support if this is incorrect.'
      );
      return;
    }

    if (Platform.OS === 'web') {
      Alert.alert(
        'Mobile only',
        'Driver live location is only supported on mobile devices.'
      );
      return;
    }

    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') {
      Alert.alert(
        'Location permission required',
        'Please allow location access to go online as a driver.'
      );
      return;
    }

    setIsOnline(true);

    const sub = await Location.watchPositionAsync(
      {
        accuracy: Location.Accuracy.High,
        timeInterval: 5000, // every 5 seconds
        distanceInterval: 5, // or when moved 5 metres
      },
      async (loc) => {
        const { latitude, longitude, heading } = loc.coords;

        await supabase.from('driver_locations').upsert({
          provider_id: providerAccount.id,
          lat: latitude,
          lng: longitude,
          heading: heading || 0,
          updated_at: new Date().toISOString(),
        });
      }
    );

    locationSubRef.current = sub;
  };

  const stopLocationUpdates = async () => {
    if (locationSubRef.current) {
      locationSubRef.current.remove();
      locationSubRef.current = null;
    }
    setIsOnline(false);

    if (providerAccount) {
      // Optional: clear location when offline
      await supabase
        .from('driver_locations')
        .delete()
        .eq('provider_id', providerAccount.id);
    }
  };

  const toggleOnline = async () => {
    if (updating) return;
    setUpdating(true);
    try {
      if (isOnline) {
        await stopLocationUpdates();
      } else {
        await startLocationUpdates();
      }
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
        <Text>Loading provider data...</Text>
      </View>
    );
  }

  if (!providerAccount) {
    return (
      <View style={styles.center}>
        <Text style={styles.warning}>
          You do not have a provider account yet.
        </Text>
        <Text style={styles.note}>
          Please apply through the "Become Provider" tab.
        </Text>
      </View>
    );
  }

  if (!providerAccount.is_active) {
    return (
      <View style={styles.center}>
        <Text style={styles.warning}>
          Your provider account is not active yet.
        </Text>
        <Text style={styles.note}>
          If you have already applied, Wantok Service Support is reviewing your details.
        </Text>
      </View>
    );
  }

  const isDriver = !!providerAccount.service_type?.includes?.('driver');
  const isVendor = !!providerAccount.service_type?.some?.((t: string) =>
    ['food_vendor', 'shop'].includes(t)
  );

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Provider Hub</Text>
      <Text style={styles.subtitle}>
        Welcome, {providerAccount.display_name || 'Partner'}.
      </Text>

      {isDriver && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Driver Mode</Text>
          <Text style={styles.cardText}>
            When you are online, nearby riders can see you and Wantok Service can assign trips to you.
          </Text>

          <TouchableOpacity
            style={[styles.onlineBtn, isOnline && styles.onlineBtnActive]}
            onPress={toggleOnline}
            disabled={updating}
          >
            {updating ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.onlineBtnText}>
                {isOnline ? 'Go Offline' : 'Go Online'}
              </Text>
            )}
          </TouchableOpacity>

          <Text style={styles.statusLine}>
            Status: {isOnline ? 'Online & sharing location' : 'Offline'}
          </Text>

          {Platform.OS === 'web' && (
            <Text style={styles.note}>
              Live location updates only work on mobile devices.
            </Text>
          )}
        </View>
      )}

      {isVendor && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Vendor Tools</Text>
          <Text style={styles.cardText}>
            Here you will manage your services, items, pricing and orders.
            (This module will be implemented next.)
          </Text>
        </View>
      )}

      {!isDriver && !isVendor && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>No active services configured</Text>
          <Text style={styles.cardText}>
            Your provider account is active, but there are no specific service types configured.
            Please contact Wantok Service Support to update your roles.
          </Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16 },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 16,
  },
  title: { fontSize: 20, fontWeight: '700' },
  subtitle: { fontSize: 13, marginTop: 4, color: '#555' },
  card: {
    marginTop: 16,
    padding: 14,
    borderRadius: 12,
    backgroundColor: '#fff',
    elevation: 2,
  },
  cardTitle: { fontSize: 16, fontWeight: '700', marginBottom: 4 },
  cardText: { fontSize: 13, color: '#555' },
  onlineBtn: {
    marginTop: 10,
    paddingVertical: 10,
    borderRadius: 20,
    backgroundColor: '#444',
    alignItems: 'center',
  },
  onlineBtnActive: {
    backgroundColor: '#0a8f3c',
  },
  onlineBtnText: { color: '#fff', fontSize: 15, fontWeight: '600' },
  statusLine: { marginTop: 6, fontSize: 12, color: '#333' },
  note: {
    marginTop: 4,
    fontSize: 11,
    color: '#777',
    textAlign: 'center',
  },
  warning: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 6,
    textAlign: 'center',
  },
});
