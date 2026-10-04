import React from 'react';
import MapView, { Marker, UrlTile } from 'react-native-maps';
import type { TaxiMapProps } from './TaxiMap.types';

export default function TaxiMap({
  region,
  pickup,
  destination,
  drivers,
  onRegionChangeComplete,
  onPress,
}: TaxiMapProps) {
  return (
    <MapView
      style={{ flex: 1 }}
      region={region}
      onRegionChangeComplete={onRegionChangeComplete}
      onPress={(event) => onPress(event.nativeEvent.coordinate)}
      showsUserLocation
    >
      <UrlTile
        urlTemplate="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        maximumZ={19}
        flipY={false}
      />

      {pickup && <Marker coordinate={pickup} title="Pickup" pinColor="green" />}

      {destination && (
        <Marker coordinate={destination} title="Destination" pinColor="red" />
      )}

      {drivers.map((driver) => (
        <Marker
          key={driver.driver_id}
          coordinate={{ latitude: driver.lat, longitude: driver.lng }}
          title={driver.name || 'Driver'}
          description={driver.vehicle_model || 'Online driver'}
          pinColor="gold"
        />
      ))}
    </MapView>
  );
}
