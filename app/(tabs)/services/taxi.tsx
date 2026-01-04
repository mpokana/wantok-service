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
import MapView, {
  Marker,
  UrlTile,
  MapPressEvent,
  Region,
} from 'react-native-maps';
import { supabase } from '../../../lib/supabase';
import { useAuthProfile } from '../../../hooks/useAuthProfile';
import DriverCard from '../../../components/DriverCard';

type LatLng = {
  latitude: number;
  longitude: number;
};

type DriverOnMap = {
  driver_id: string;
  name?: string | null;
  phone?: string | null;
  vehicle_rego?: string | null;
  vehicle_model?: string | null;
  vehicle_colour?: string | null;
  vehicle_image_url?: string | null;
  lat: number;
  lng: number;
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
  const [region, setRegion] = useState<Region | null>(null);
  const [userLocation, setUserLocation] = useState<LatLng | null>(null);
  const [pickup, setPickup] = useState<LatLng | null>(null);
  const [destination, setDestination] = useState<LatLng | null>(null);
  const [selectionMode, setSelectionMode] = useState<SelectionMode>('pickup');

  const [drivers, setDrivers] = useState<DriverOnMap[]>([]);
  const [loadingMap, setLoadingMap] = useState(true);
  const [requesting, setRequesting] = useState(false);
  const [fareEstimate, setFareEstimate] = useState<number | null>(null);
  const [selectedDriver, setSelectedDriver] = useState<DriverOnMap | null>(null);
  const [selectedDriverDistance, setSelectedDriverDistance] = useState<number | null>(null);
  const [rideId, setRideId] = useState<string | null>(null);

  // Init map + default pickup
  useEffect(() => {
    (async () => {
      try {
        const { status } = await Location.requestForegroundPermissionsAsync();

        if (status !== 'granted') {
          Alert.alert('Location permission', 'Please enable location to book a ride.');
          const fallback: Region = {
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

        setUserLocation(coords);
        setPickup(coords);
        setRegion({
          ...coords,
          latitudeDelta: 0.05,
          longitudeDelta: 0.05,
        });
      } catch (error) {
        console.log('Location error', error);
        const fallback: Region = {
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
      const { data, error } = await supabase
        .from('driver_locations')
        .select(`
          driver_id,
          lat,
          lng,
          is_online,
          profiles:driver_id (
            full_name,
            phone,
            is_driver,
            is_driver_approved
          ),
          driver_profiles:driver_id (
            vehicle_rego,
            vehicle_model,
            vehicle_colour,
            vehicle_image_url
          )
        `)
        .eq('is_online', true);

      if (error) {
        console.log('Error loading drivers', error);
        return;
      }

      if (!data) return;

      setDrivers(
        data
          .filter(
            (d: any) =>
              d.profiles?.is_driver &&
              d.profiles?.is_driver_approved &&
              d.is_online
          )
          .map((d: any) => ({
            driver_id: d.driver_id,
            name: d.profiles?.full_name,
            phone: d.profiles?.phone,
            lat: d.lat,
            lng: d.lng,
            vehicle_rego: d.driver_profiles?.vehicle_rego,
            vehicle_model: d.driver_profiles?.vehicle_model,
            vehicle_colour: d.driver_profiles?.vehicle_colour,
            vehicle_image_url: d.driver_profiles?.vehicle_image_url,
          }))
      );
    };

    loadDrivers();

    const channel = supabase
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

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  // ① Auto-advance + live estimate on map taps
  const handleMapPress = (e: MapPressEvent) => {
    if (!selectionMode) return;

    const coord = e.nativeEvent.coordinate;
    if (!coord) return;

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
      setUserLocation(coords);
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

    if (!drivers.length) {
      Alert.alert('No drivers', 'No approved drivers are online nearby at the moment.');
      return;
    }

    setRequesting(true);

    try {
      // Find nearest online driver
      const candidates = drivers.map(d => ({
        ...d,
        distanceKm: haversineKm(pickup, {
          latitude: d.lat,
          longitude: d.lng,
        }),
      }));

      candidates.sort((a, b) => a.distanceKm - b.distanceKm);
      const nearest = candidates[0];

      const tripDistanceKm = haversineKm(pickup, destination);
      const estimate = calculateFare(tripDistanceKm);

      const { data, error } = await supabase
        .from('rides')
        .insert({
          passenger_id: session.user.id,
          driver_id: nearest.driver_id,
          pickup_lat: pickup.latitude,
          pickup_lng: pickup.longitude,
          dropoff_lat: destination.latitude,
          dropoff_lng: destination.longitude,
          status: 'driver_assigned',
          fare_estimate: estimate,
          distance_km: tripDistanceKm,
        })
        .select()
        .single();

      if (error || !data) {
        console.log('Ride create error', error);
        Alert.alert('Error', 'Could not create ride. Please try again.');
        setRequesting(false);
        return;
      }

      setRideId(data.id);
      setFareEstimate(estimate);
      setSelectedDriver(nearest);
      setSelectedDriverDistance(nearest.distanceKm ?? null);

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
        await supabase.from('rides').update({ status: 'cancelled' }).eq('id', rideId);
      }
    } catch (err) {
      console.log('Cancel ride error', err);
    } finally {
      setRideId(null);
      setFareEstimate(null);
      setSelectedDriver(null);
      setSelectedDriverDistance(null);
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
      <MapView
        style={styles.map}
        region={region}
        onRegionChangeComplete={setRegion}
        onPress={handleMapPress}
        showsUserLocation
      >
        <UrlTile
          urlTemplate="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
          maximumZ={19}
          flipY={false}
        />

        {pickup && <Marker coordinate={pickup} title="Pickup" pinColor="green" />}

        {destination && (
          <Marker
            coordinate={destination}
            title="Destination"
            pinColor="red"
          />
        )}

        {drivers.map(driver => (
          <Marker
            key={driver.driver_id}
            coordinate={{
              latitude: driver.lat,
              longitude: driver.lng,
            }}
            title={driver.name || 'Driver'}
            description={driver.vehicle_model || 'Online driver'}
            pinColor="gold"
          />
        ))}
      </MapView>

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
