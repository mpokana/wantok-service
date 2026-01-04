import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Switch,
  Alert,
  ActivityIndicator,
} from 'react-native';
import * as Location from 'expo-location';
import { supabase } from '../../lib/supabase';
import { useAuthProfile } from '../../hooks/useAuthProfile';

export default function ProviderScreen() {
  const { profile, session, loading } = useAuthProfile();
  const [isOnline, setIsOnline] = useState(false);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    let interval: ReturnType<typeof setInterval> | null = null;

    const startTracking = async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        Alert.alert('Location required', 'Please enable location to go online.');
        setIsOnline(false);
        return;
      }

      interval = setInterval(async () => {
        try {
          const loc = await Location.getCurrentPositionAsync({});
          const { latitude, longitude, heading } = loc.coords;

          if (!session?.user) return;

          await supabase
            .from('driver_locations')
            .upsert(
              {
                driver_id: session.user.id,
                lat: latitude,
                lng: longitude,
                heading: heading ?? null,
                is_online: true,
                updated_at: new Date().toISOString(),
              },
              { onConflict: 'driver_id' },
            );
        } catch (error) {
          console.log('Location update error', error);
        }
      }, 7000);
    };

    if (isOnline) {
      setUpdating(true);
      startTracking().finally(() => setUpdating(false));
    } else {
      (async () => {
        if (session?.user) {
          try {
            await supabase
              .from('driver_locations')
              .update({ is_online: false })
              .eq('driver_id', session.user.id);
          } catch (err) {
            console.log('Error updating driver status', err);
          }
        }
      })();

      if (interval) clearInterval(interval);
    }

    return () => {
      if (interval) clearInterval(interval);
    };
  }, [isOnline, session?.user]);

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#FACC15" />
      </View>
    );
  }

  if (!profile?.is_provider) {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>Provider</Text>
        <Text style={styles.text}>You are not registered as a provider yet.</Text>
        <Text style={styles.textSmall}>
          Use the Apply tab or contact admin to register as a driver, venue host,
          or specialist.
        </Text>
      </View>
    );
  }

  if (profile.is_driver && !profile.is_driver_approved) {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>Driver</Text>
        <Text style={styles.text}>Your driver application is pending approval.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Provider Dashboard</Text>

      {profile.is_driver && profile.is_driver_approved && (
        <>
          <Text style={styles.sectionLabel}>Driver status</Text>
          <View style={styles.row}>
            <Text style={styles.text}>
              {isOnline ? 'Online (visible to passengers)' : 'Offline'}
            </Text>
            <Switch
              value={isOnline}
              onValueChange={setIsOnline}
              trackColor={{ false: '#4B5563', true: '#22C55E' }}
              thumbColor="#F9FAFB"
            />
          </View>
          {updating && (
            <Text style={styles.textSmall}>Updating your location…</Text>
          )}
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    backgroundColor: '#000',
    alignItems: 'center',
    justifyContent: 'center',
  },
  container: {
    flex: 1,
    backgroundColor: '#000',
    padding: 20,
    paddingTop: 50,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#FACC15',
    marginBottom: 10,
  },
  sectionLabel: {
    fontSize: 13,
    color: '#9CA3AF',
    marginTop: 16,
    marginBottom: 6,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  text: { color: '#E5E7EB', fontSize: 14 },
  textSmall: { color: '#9CA3AF', fontSize: 11, marginTop: 4 },
});
