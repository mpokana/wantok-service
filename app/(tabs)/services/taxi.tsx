import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  ActivityIndicator,
  Linking,
} from 'react-native';
import * as Location from 'expo-location';
import TaxiMap from '../../../components/TaxiMap';
import DriverCard from '../../../components/DriverCard';
import type {
  LatLng,
  TaxiMapDriver,
  TaxiMapRegion,
} from '../../../components/TaxiMap.types';
import { useAuthProfile } from '../../../hooks/useAuthProfile';
import { supabase } from '../../../lib/supabase';

type DriverOnMap = TaxiMapDriver;

type AssignedDriver = {
  driver_id: string;
  name?: string | null;
  phone?: string | null;
  vehicle_rego?: string | null;
  vehicle_model?: string | null;
  vehicle_colour?: string | null;
  vehicle_image_url?: string | null;
};

type RideRequestResult = {
  ride_id: string;
  driver_id: string;
  driver_name: string | null;
  driver_phone: string | null;
  vehicle_rego: string | null;
  vehicle_model: string | null;
  vehicle_colour: string | null;
  vehicle_image_url: string | null;
  driver_distance_km: number;
  trip_distance_km: number;
  fare_estimate: number | string;
};

type SelectionMode = 'pickup' | 'destination' | null;

function haversineKm(a: LatLng, b: LatLng): number {
  const toRad = (v: number) => (v * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(b.latitude - a.latitude);
  const dLng = toRad(b.longitude - a.longitude);
  const lat1 = toRad(a.latitude);
  const lat2 = toRad(b.latitude);

  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;

  return 2 * R * Math.asin(Math.sqrt(h));
}

function calculateFare(distanceKm: number): number {
  const base = 5; // K5 flagfall
  const perKm = 2.5; // K2.50 per km
  const fare = base + perKm * distanceKm;
  return Math.max(fare, 8); // min K8
}

export default function TaxiScreen() {
  const { session } = useAuthProfile();
  const [region, setRegion] = useState<TaxiMapRegion | null>(null);
  const [pickup, setPickup] = useState<LatLng | null>(null);
  const [destination, setDestination] = useState<LatLng | null>(null);
  const [selectionMode, setSelectionMode] = useState<SelectionMode>('pickup');

  const [drivers, setDrivers] = useState<DriverOnMap[]>([]);
  const [loadingMap, setLoadingMap] = useState(true);
  const [requesting, setRequesting] = useState(false);
  const [fareEstimate, setFareEstimate] = useState<number | null>(null);
  const [selectedDriver, setSelectedDriver] = useState<AssignedDriver | null>(null);
  const [selectedDriverDistance, setSelectedDriverDistance] = useState<number | null>(null);
  const [rideId, setRideId] = useState<string | null>(null);

  // Init map + default pickup
  useEffect(() => {
    (async () => {
      try {
        const { status } = await Location.requestForegroundPermissionsAsync();

        if (status !== 'granted') {
          Alert.alert('Location permission', 'Please enable location to book a ride.');
          const fallback: TaxiMapRegion = {
            latitude: -6.0,
            longitude: 147.0,
            latitudeDelta: 5,
            longitudeDelta: 5,
          };
          setRegion(fallback);
          setLoadingMap(false);
          return;
        }

        const loc = await Location.getCurrentPositionAsync({});
        const coords: LatLng = {
          latitude: loc.coords.latitude,
          longitude: loc.coords.longitude,
        };

        setPickup(coords);
        setRegion({
          ...coords,
          latitudeDelta: 0.05,
          longitudeDelta: 0.05,
        });
      } catch (error) {
        console.log('Location error', error);
        const fallback: TaxiMapRegion = {
          latitude: -6.0,
          longitude: 147.0,
          latitudeDelta: 5,
          longitudeDelta: 5,
        };
        setRegion(fallback);
      } finally {
        setLoadingMap(false);
      }
    })();
  }, []);

  // Load existing online drivers + subscribe realtime
  useEffect(() => {
    const loadDrivers = async () => {
      const { data, error } = await supabase.rpc('list_available_drivers');

      if (error) {
        console.log('Error loading drivers', error);
        return;
      }

      setDrivers(
        ((data || []) as DriverOnMap[]).map((driver) => ({
          ...driver,
          phone: null,
        }))
      );
    };

    loadDrivers();

    const locationChannel = supabase
      .channel('driver_locations_realtime')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'driver_locations',
        },
        (payload: any) => {
          const row = payload.new || payload.old;
          if (!row) return;

          setDrivers(prev => {
            // Remove if deleted or offline
            if (payload.eventType === 'DELETE' || !row.is_online) {
              return prev.filter(d => d.driver_id !== row.driver_id);
            }

            // Update existing
            const existing = prev.find(d => d.driver_id === row.driver_id);

            if (existing) {
              return prev.map(d =>
                d.driver_id === row.driver_id
                  ? {
                      ...existing,
                      lat: row.lat,
                      lng: row.lng,
                    }
                  : d
              );
            }

            // New driver (minimal info; full meta from next reload if needed)
            return [
              ...prev,
              {
                driver_id: row.driver_id,
                lat: row.lat,
                lng: row.lng,
              } as DriverOnMap,
            ];
          });
        }
      )
      .subscribe();

    const ridesChannel = supabase
      .channel('rides_availability_realtime')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'rides' },
        () => {
          loadDrivers();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(locationChannel);
      supabase.removeChannel(ridesChannel);
    };
  }, []);

  // Auto-advance + live estimate on map taps
  const handleMapPress = (coord: LatLng) => {
    if (!selectionMode) return;

    if (selectionMode === 'pickup') {
      setPickup(coord);
      // auto-advance to destination selection
      setSelectionMode('destination');
      // reset prior estimate when pickup changes
      setFareEstimate(null);
    } else if (selectionMode === 'destination') {
      setDestination(coord);
      // stop selection (both set)
      setSelectionMode(null);
      // compute live estimate
      const tripKm = pickup ? haversineKm(pickup, coord) : 0;
      setFareEstimate(Number.isFinite(tripKm) ? calculateFare(tripKm) : null);
    }
  };

  const recenterOnUser = async () => {
    try {
      const loc = await Location.getCurrentPositionAsync({});
      const coords: LatLng = {
        latitude: loc.coords.latitude,
        longitude: loc.coords.longitude,
      };
      setRegion({
        ...coords,
        latitudeDelta: 0.05,
        longitudeDelta: 0.05,
      });
    } catch {
      Alert.alert('Error', 'Could not recenter on your location.');
    }
  };

  const formatCoord = (point: LatLng | null) => {
    if (!point) return 'Not set';
    return `${point.latitude.toFixed(4)}, ${point.longitude.toFixed(4)}`;
  };

  const handleRequestRide = async () => {
    // ② Guard: prevent double booking or double tap
    if (requesting) return;

    if (rideId) {
      Alert.alert('Ride already active', 'Cancel your current ride before creating a new one.');
      return;
    }

    if (!session?.user) {
      Alert.alert('Login required', 'Please log in to request a ride.');
      return;
    }

    if (!pickup || !destination) {
      Alert.alert('Select locations', 'Tap on the map to set pickup and destination first.');
      return;
    }

    setRequesting(true);

    try {
      const { data, error } = await supabase.rpc('request_ride', {
        p_pickup_lat: pickup.latitude,
        p_pickup_lng: pickup.longitude,
        p_dropoff_lat: destination.latitude,
        p_dropoff_lng: destination.longitude,
      });

      const assignment = ((data || []) as RideRequestResult[])[0];

      if (error || !assignment) {
        console.log('Ride create error', error);
        const message = error?.message || 'Could not create ride. Please try again.';
        Alert.alert(
          message.includes('No approved drivers') ? 'No drivers' : 'Ride request failed',
          message
        );
        return;
      }

      const estimate = Number(assignment.fare_estimate);

      setRideId(assignment.ride_id);
      setFareEstimate(Number.isFinite(estimate) ? estimate : null);
      setSelectedDriver({
        driver_id: assignment.driver_id,
        name: assignment.driver_name,
        phone: assignment.driver_phone,
        vehicle_rego: assignment.vehicle_rego,
        vehicle_model: assignment.vehicle_model,
        vehicle_colour: assignment.vehicle_colour,
        vehicle_image_url: assignment.vehicle_image_url,
      });
      setSelectedDriverDistance(assignment.driver_distance_km);
      setDrivers((previous) =>
        previous.filter((driver) => driver.driver_id !== assignment.driver_id)
      );

      Alert.alert('Ride requested', 'We have assigned the nearest available driver.');
    } catch (err) {
      console.log('Ride request error', err);
      Alert.alert('Error', 'Something went wrong. Try again.');
    } finally {
      setRequesting(false);
    }
  };

  const handleCancelRide = async () => {
    try {
      if (rideId) {
        const { error } = await supabase
          .from('rides')
          .update({ status: 'cancelled' })
          .eq('id', rideId);

        if (error) throw error;
      }

      setRideId(null);
      setFareEstimate(null);
      setSelectedDriver(null);
      setSelectedDriverDistance(null);
    } catch (err) {
      console.log('Cancel ride error', err);
      Alert.alert('Cancellation failed', 'Could not cancel this ride. Please try again.');
    }
  };

  if (loadingMap || !region) {
    return (
      <View style={stylesLoading.container}>
        <ActivityIndicator color="#FACC15" />
        <Text style={stylesLoading.text}>Preparing map…</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <TaxiMap
        region={region}
        pickup={pickup}
        destination={destination}
        drivers={drivers}
        onRegionChangeComplete={setRegion}
        onPress={handleMapPress}
      />

      {/* recenter button */}
      <View style={styles.recenterContainer}>
        <TouchableOpacity style={styles.recenterButton} onPress={recenterOnUser}>
          <Text style={styles.recenterIcon}>◎</Text>
        </TouchableOpacity>
      </View>

      {/* bottom controls (only if no assigned driver) */}
      {!selectedDriver && (
        <View style={styles.bottom}>
          <Text style={styles.heading}>Wantok Taxi</Text>
          <Text style={styles.info}>
            Tap the map to set pickup and destination, then request the nearest approved driver.
          </Text>

          <View style={styles.modeRow}>
            <TouchableOpacity
              style={[styles.modeButton, selectionMode === 'pickup' && styles.modeButtonActive]}
              onPress={() => {
                setSelectionMode('pickup');
                setFareEstimate(null); // reset estimate when changing mode
              }}
            >
              <Text style={styles.modeButtonText}>Set Pickup</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.modeButton, selectionMode === 'destination' && styles.modeButtonActive]}
              onPress={() => setSelectionMode('destination')}
            >
              <Text style={styles.modeButtonText}>Set Destination</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.coordBlock}>
            <Text style={styles.coordLabel}>Pickup</Text>
            <Text style={styles.coordValue}>{formatCoord(pickup)}</Text>
          </View>

          <View style={styles.coordBlock}>
            <Text style={styles.coordLabel}>Destination</Text>
            <Text style={styles.coordValue}>{formatCoord(destination)}</Text>
          </View>

          {/* ③ Live estimate block */}
          {pickup && destination && (
            <View style={{ marginTop: 6, marginBottom: 6 }}>
              <Text style={{ color: '#6B7280', fontSize: 10, fontWeight: '600' }}>
                Estimate
              </Text>
              <Text style={{ color: '#E5E7EB', fontSize: 12 }}>
                {(() => {
                  const km = haversineKm(pickup, destination);
                  const fare = calculateFare(km);
                  return `Distance: ${km.toFixed(2)} km   •   Fare: K${fare.toFixed(2)}`;
                })()}
              </Text>
            </View>
          )}

          <TouchableOpacity
            style={[styles.button, requesting && { opacity: 0.6 }]}
            onPress={handleRequestRide}
            disabled={requesting}
          >
            {requesting ? (
              <ActivityIndicator color="#FFFFFF" />
            ) : (
              <Text style={styles.buttonText}>Request Nearest Driver</Text>
            )}
          </TouchableOpacity>
        </View>
      )}

      {/* Driver card when ride assigned */}
      {selectedDriver && (
        <DriverCard
          name={selectedDriver.name}
          phone={selectedDriver.phone}
          vehicle_rego={selectedDriver.vehicle_rego}
          vehicle_model={selectedDriver.vehicle_model}
          vehicle_colour={selectedDriver.vehicle_colour}
          vehicle_image_url={selectedDriver.vehicle_image_url}
          distanceKm={selectedDriverDistance}
          fareEstimate={fareEstimate}
          onCallPress={() => {
            if (selectedDriver.phone) {
              Linking.openURL(`tel:${selectedDriver.phone}`);
            }
          }}
          onMessagePress={() => {
            if (selectedDriver.phone) {
              Linking.openURL(`sms:${selectedDriver.phone}`);
            }
          }}
          onCancelPress={handleCancelRide}
        />
      )}
    </View>
  );
}

/* styles */

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000000' },
  map: { flex: 1 },
  bottom: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    paddingHorizontal: 16,
    paddingTop: 10,
    paddingBottom: 18,
    backgroundColor: '#000000',
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    borderTopWidth: 1,
    borderColor: '#27272A',
  },
  heading: {
    color: '#FACC15',
    fontSize: 16,
    fontWeight: '700',
    marginBottom: 4,
  },
  info: {
    color: '#9CA3AF',
    fontSize: 11,
    marginBottom: 8,
  },
  modeRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  modeButton: {
    flex: 1,
    paddingVertical: 8,
    marginHorizontal: 2,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#4B5563',
    alignItems: 'center',
  },
  modeButtonActive: {
    backgroundColor: '#B91C1C',
    borderColor: '#B91C1C',
  },
  modeButtonText: {
    fontSize: 12,
    fontWeight: '500',
    color: '#F9FAFB',
  },
  coordBlock: {
    marginBottom: 4,
  },
  coordLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: '#6B7280',
  },
  coordValue: {
    fontSize: 11,
    color: '#E5E7EB',
  },
  button: {
    marginTop: 10,
    backgroundColor: '#B91C1C',
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
  },
  buttonText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 14,
  },
  recenterContainer: {
    position: 'absolute',
    top: 60,
    right: 16,
  },
  recenterButton: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 6,
  },
  recenterIcon: {
    fontSize: 18,
    color: '#000000',
  },
});

const stylesLoading = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  text: {
    color: '#E5E7EB',
    marginTop: 8,
    fontSize: 13,
    textAlign: 'center',
  },
});
