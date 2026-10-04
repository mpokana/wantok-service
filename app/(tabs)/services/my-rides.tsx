import React, { useCallback, useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  ActivityIndicator,
  RefreshControl,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { supabase } from '../../../lib/supabase';
import { useAuthProfile } from '../../../hooks/useAuthProfile';

type Ride = {
  id: string;
  status: string; // 'driver_assigned' | 'in_progress' | 'completed' | 'cancelled' | etc.
  fare_estimate: number | null;
  distance_km: number | null;
  pickup_lat: number;
  pickup_lng: number;
  dropoff_lat: number;
  dropoff_lng: number;
  created_at: string;
};

export default function MyRidesScreen() {
  const { session } = useAuthProfile();
  const [rides, setRides] = useState<Ride[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const canCancel = (status: string) =>
    status === 'driver_assigned' || status === 'pending';

  const fetchRides = useCallback(async () => {
    if (!session?.user) {
      setRides([]);
      setLoading(false);
      return;
    }
    try {
      const { data, error } = await supabase
        .from('rides')
        .select(
          `
          id,
          status,
          fare_estimate,
          distance_km,
          pickup_lat,
          pickup_lng,
          dropoff_lat,
          dropoff_lng,
          created_at
        `
        )
        .eq('passenger_id', session.user.id)
        .order('created_at', { ascending: false });

      if (error) {
        console.log('fetchRides error', error);
        return;
      }
      setRides(data as Ride[]);
    } finally {
      setLoading(false);
    }
  }, [session?.user]);

  useEffect(() => {
    fetchRides();
  }, [fetchRides]);

  // Realtime updates for the signed-in passenger
  useEffect(() => {
    if (!session?.user) return;

    const channel = supabase
      .channel('rides_realtime_my_list')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'rides' },
        (payload: any) => {
          const row = payload.new || payload.old;
          if (!row || row.passenger_id !== session.user.id) return;

          setRides(prev => {
            if (payload.eventType === 'INSERT') {
              // Put newest at the top
              const next = [row as Ride, ...prev];
              // Guard against duplicates
              const seen = new Set<string>();
              return next.filter(r => (seen.has(r.id) ? false : seen.add(r.id)));
            }

            if (payload.eventType === 'UPDATE') {
              return prev.map(r => (r.id === row.id ? { ...(r as Ride), ...(row as Ride) } : r));
            }

            if (payload.eventType === 'DELETE') {
              return prev.filter(r => r.id !== row.id);
            }

            return prev;
          });
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [session?.user]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await fetchRides();
    setRefreshing(false);
  }, [fetchRides]);

  const handleCancel = async (ride: Ride) => {
    try {
      const { error } = await supabase
        .from('rides')
        .update({ status: 'cancelled' })
        .eq('id', ride.id);

      if (error) {
        Alert.alert('Error', 'Could not cancel this ride, please try again.');
        return;
      }
      // Optimistic UI: update local list
      setRides(prev => prev.map(r => (r.id === ride.id ? { ...r, status: 'cancelled' } : r)));
    } catch {
      Alert.alert('Error', 'Something went wrong.');
    }
  };

  if (!session?.user) {
    return (
      <View style={styles.center}>
        <Text style={styles.muted}>Please sign in to view your rides.</Text>
      </View>
    );
  }

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
        <Text style={styles.muted}>Loading your rides…</Text>
      </View>
    );
  }

  if (!rides.length) {
    return (
      <View style={styles.center}>
        <Text style={styles.title}>My Rides</Text>
        <Text style={styles.muted}>You have no rides yet.</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.header}>My Rides</Text>

      <FlatList
        data={rides}
        keyExtractor={(item) => item.id}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
        contentContainerStyle={{ paddingBottom: 24 }}
        renderItem={({ item }) => (
          <View style={styles.card}>
            <View style={styles.rowBetween}>
              <Text style={styles.cardTitle}>
                {formatStatus(item.status)}
              </Text>
              <Text style={styles.timestamp}>
                {new Date(item.created_at).toLocaleString()}
              </Text>
            </View>

            <View style={styles.coordsWrap}>
              <Text style={styles.label}>Pickup</Text>
              <Text style={styles.value}>
                {fmt(item.pickup_lat)},{' '}{fmt(item.pickup_lng)}
              </Text>
            </View>

            <View style={styles.coordsWrap}>
              <Text style={styles.label}>Drop-off</Text>
              <Text style={styles.value}>
                {fmt(item.dropoff_lat)},{' '}{fmt(item.dropoff_lng)}
              </Text>
            </View>

            <View style={styles.metrics}>
              {item.distance_km != null && (
                <Text style={styles.metric}>
                  Distance: {item.distance_km.toFixed(2)} km
                </Text>
              )}
              {item.fare_estimate != null && (
                <Text style={styles.metric}>
                  Est. Fare: K{item.fare_estimate.toFixed(2)}
                </Text>
              )}
            </View>

            <View style={styles.actions}>
              <View style={[styles.statusPill, pillColor(item.status)]}>
                <Text style={styles.statusText}>{formatStatus(item.status)}</Text>
              </View>

              {canCancel(item.status) && (
                <TouchableOpacity
                  style={styles.cancelBtn}
                  onPress={() =>
                    Alert.alert(
                      'Cancel ride',
                      'Are you sure you want to cancel this ride?',
                      [
                        { text: 'No' },
                        { text: 'Yes, cancel', style: 'destructive', onPress: () => handleCancel(item) },
                      ]
                    )
                  }
                >
                  <Text style={styles.cancelText}>Cancel</Text>
                </TouchableOpacity>
              )}
            </View>
          </View>
        )}
      />
    </View>
  );
}

/* helpers */

const fmt = (n: number) => n.toFixed(5);

const formatStatus = (s: string) => {
  switch (s) {
    case 'pending': return 'Pending';
    case 'driver_assigned': return 'Driver Assigned';
    case 'in_progress': return 'In Progress';
    case 'completed': return 'Completed';
    case 'cancelled': return 'Cancelled';
    default: return s;
  }
};

const pillColor = (s: string) => {
  if (s === 'completed') return { backgroundColor: '#14532d' };
  if (s === 'cancelled') return { backgroundColor: '#7f1d1d' };
  if (s === 'in_progress') return { backgroundColor: '#1e3a8a' };
  if (s === 'driver_assigned' || s === 'pending') return { backgroundColor: '#78350f' };
  return { backgroundColor: '#374151' };
};

/* styles */

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000000', paddingHorizontal: 12, paddingTop: 8 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: '#000000', padding: 24 },
  header: { color: '#FACC15', fontSize: 18, fontWeight: '800', marginVertical: 8 },
  title: { color: '#FACC15', fontSize: 16, fontWeight: '700', marginBottom: 4 },
  muted: { color: '#9CA3AF', fontSize: 12, textAlign: 'center' },

  card: {
    backgroundColor: '#0a0a0a',
    borderWidth: 1,
    borderColor: '#27272A',
    borderRadius: 12,
    padding: 12,
    marginBottom: 10,
  },
  rowBetween: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 },
  cardTitle: { color: '#F3F4F6', fontWeight: '700', fontSize: 14 },
  timestamp: { color: '#9CA3AF', fontSize: 11 },

  coordsWrap: { marginTop: 4 },
  label: { color: '#6B7280', fontSize: 11, fontWeight: '600' },
  value: { color: '#E5E7EB', fontSize: 12 },

  metrics: { flexDirection: 'row', gap: 14, marginTop: 8 },
  metric: { color: '#D1D5DB', fontSize: 12 },

  actions: { marginTop: 10, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  statusPill: { paddingVertical: 4, paddingHorizontal: 8, borderRadius: 999 },
  statusText: { color: '#F9FAFB', fontSize: 11, fontWeight: '700' },

  cancelBtn: {
    borderRadius: 8,
    borderColor: '#991b1b',
    borderWidth: 1,
    paddingVertical: 6,
    paddingHorizontal: 10,
  },
  cancelText: { color: '#ef4444', fontWeight: '700', fontSize: 12 },
});
