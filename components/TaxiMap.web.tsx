import React, { useEffect, useRef, useState } from 'react';
import { Text, View } from 'react-native';
import type {
  LatLng,
  TaxiMapProps,
  TaxiMapRegion,
} from './TaxiMap.types';
import 'maplibre-gl/dist/maplibre-gl.css';

const clamp = (value: number, min: number, max: number) =>
  Math.min(max, Math.max(min, value));

const deltaToZoom = (longitudeDelta: number) =>
  clamp(Math.log2(360 / Math.max(longitudeDelta, 0.0001)), 1, 19);

export default function TaxiMap({
  region,
  pickup,
  destination,
  drivers,
  onRegionChangeComplete,
  onPress,
}: TaxiMapProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<import('maplibre-gl').Map | null>(null);
  const maplibreRef = useRef<typeof import('maplibre-gl') | null>(null);
  const markerRefs = useRef<import('maplibre-gl').Marker[]>([]);
  const onPressRef = useRef(onPress);
  const onRegionChangeRef = useRef(onRegionChangeComplete);
  const initialRegionRef = useRef(region);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    onPressRef.current = onPress;
  }, [onPress]);

  useEffect(() => {
    onRegionChangeRef.current = onRegionChangeComplete;
  }, [onRegionChangeComplete]);

  useEffect(() => {
    let cancelled = false;

    const initialise = async () => {
      const maplibre = await import('maplibre-gl');
      if (cancelled || !containerRef.current) return;

      maplibreRef.current = maplibre;

      const initialRegion = initialRegionRef.current;
      const map = new maplibre.Map({
        container: containerRef.current,
        center: [initialRegion.longitude, initialRegion.latitude],
        zoom: deltaToZoom(initialRegion.longitudeDelta),
        attributionControl: { compact: true },
        style: {
          version: 8,
          sources: {
            osm: {
              type: 'raster',
              tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
              tileSize: 256,
              attribution: '© OpenStreetMap contributors',
            },
          },
          layers: [
            {
              id: 'osm',
              type: 'raster',
              source: 'osm',
            },
          ],
        },
      });

      mapRef.current = map;
      map.addControl(new maplibre.NavigationControl(), 'top-right');

      map.on('click', (event) => {
        onPressRef.current({
          latitude: event.lngLat.lat,
          longitude: event.lngLat.lng,
        });
      });

      map.on('moveend', () => {
        const centre = map.getCenter();
        const bounds = map.getBounds();
        if (!bounds) return;

        const nextRegion: TaxiMapRegion = {
          latitude: centre.lat,
          longitude: centre.lng,
          latitudeDelta: Math.abs(bounds.getNorth() - bounds.getSouth()),
          longitudeDelta: Math.abs(bounds.getEast() - bounds.getWest()),
        };

        onRegionChangeRef.current(nextRegion);
      });

      map.once('load', () => {
        if (!cancelled) setReady(true);
      });
    };

    initialise().catch((cause: unknown) => {
      const message = cause instanceof Error ? cause.message : 'Could not load the web map.';
      setError(message);
    });

    return () => {
      cancelled = true;
      markerRefs.current.forEach((marker) => marker.remove());
      markerRefs.current = [];
      mapRef.current?.remove();
      mapRef.current = null;
      maplibreRef.current = null;
    };
  }, []);

  useEffect(() => {
    if (!ready || !mapRef.current) return;

    const map = mapRef.current;
    const centre = map.getCenter();
    const centreChanged =
      Math.abs(centre.lat - region.latitude) > 0.00001 ||
      Math.abs(centre.lng - region.longitude) > 0.00001;

    if (centreChanged) {
      map.easeTo({
        center: [region.longitude, region.latitude],
        zoom: deltaToZoom(region.longitudeDelta),
        duration: 250,
      });
    }
  }, [ready, region]);

  useEffect(() => {
    const map = mapRef.current;
    const maplibre = maplibreRef.current;
    if (!ready || !map || !maplibre) return;

    markerRefs.current.forEach((marker) => marker.remove());
    markerRefs.current = [];

    const addMarker = (
      coordinate: LatLng,
      colour: string,
      label: string,
    ) => {
      const marker = new maplibre.Marker({ color: colour })
        .setLngLat([coordinate.longitude, coordinate.latitude])
        .setPopup(new maplibre.Popup({ offset: 24 }).setText(label))
        .addTo(map);
      markerRefs.current.push(marker);
    };

    if (pickup) addMarker(pickup, '#22C55E', 'Pickup');
    if (destination) addMarker(destination, '#EF4444', 'Destination');

    drivers.forEach((driver) => {
      addMarker(
        { latitude: driver.lat, longitude: driver.lng },
        '#FACC15',
        driver.name || driver.vehicle_model || 'Online driver',
      );
    });
  }, [ready, pickup, destination, drivers]);

  if (error) {
    return (
      <View
        style={{
          flex: 1,
          minHeight: 420,
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#111827',
          padding: 24,
        }}
      >
        <Text style={{ color: '#F9FAFB', textAlign: 'center' }}>
          Web map unavailable: {error}
        </Text>
      </View>
    );
  }

  return (
    <div
      ref={containerRef}
      style={{ width: '100%', height: '100%', minHeight: 420 }}
      aria-label="Wantok Taxi map"
    />
  );
}
