import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  Image,
  TouchableOpacity,
} from 'react-native';

type DriverCardProps = {
  name?: string | null;
  phone?: string | null;
  vehicle_rego?: string | null;
  vehicle_model?: string | null;
  vehicle_colour?: string | null;
  vehicle_image_url?: string | null;
  distanceKm?: number | null;
  fareEstimate?: number | null;
  onCallPress?: () => void;
  onMessagePress?: () => void;
  onCancelPress?: () => void;
};

const DriverCard: React.FC<DriverCardProps> = ({
  name = 'Assigned driver',
  phone,
  vehicle_rego,
  vehicle_model,
  vehicle_colour,
  vehicle_image_url,
  distanceKm,
  fareEstimate,
  onCallPress,
  onMessagePress,
  onCancelPress,
}) => {
  return (
    <View style={styles.container}>
      <View style={styles.row}>
        {vehicle_image_url ? (
          <Image source={{ uri: vehicle_image_url }} style={styles.image} />
        ) : (
          <View style={styles.placeholder} />
        )}
        <View style={styles.info}>
          <Text style={styles.name}>{name}</Text>
          <Text style={styles.text}>
            {(vehicle_model || 'Vehicle') +
              ' • ' +
              (vehicle_rego || 'Rego')}
          </Text>
          {vehicle_colour && (
            <Text style={styles.textSmall}>
              Colour: {vehicle_colour}
            </Text>
          )}
          {distanceKm != null && (
            <Text style={styles.textSmall}>
              ~{distanceKm.toFixed(1)} km away
            </Text>
          )}
          {fareEstimate != null && (
            <Text style={styles.fare}>
              Est. Fare: K{fareEstimate.toFixed(2)}
            </Text>
          )}
        </View>
      </View>

      <View style={styles.actions}>
        <TouchableOpacity
          style={[styles.button, !phone && styles.buttonDisabled]}
          onPress={onCallPress}
          disabled={!phone}
        >
          <Text style={styles.buttonText}>Call</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, !phone && styles.buttonDisabled]}
          onPress={onMessagePress}
          disabled={!phone}
        >
          <Text style={styles.buttonText}>Message</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.buttonOutline}
          onPress={onCancelPress}
        >
          <Text style={styles.buttonOutlineText}>Cancel</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

export default DriverCard;

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    left: 12,
    right: 12,
    bottom: 18,
    padding: 12,
    borderRadius: 14,
    backgroundColor: '#000',
    borderWidth: 1,
    borderColor: '#27272A',
  },
  row: {
    flexDirection: 'row',
    marginBottom: 6,
  },
  image: {
    width: 56,
    height: 56,
    borderRadius: 10,
    marginRight: 10,
  },
  placeholder: {
    width: 56,
    height: 56,
    borderRadius: 10,
    marginRight: 10,
    backgroundColor: '#18181B',
  },
  info: {
    flex: 1,
    justifyContent: 'center',
  },
  name: { fontSize: 16, fontWeight: '600', color: '#FACC15' },
  text: { fontSize: 13, color: '#E5E7EB' },
  textSmall: { fontSize: 11, color: '#9CA3AF' },
  fare: { marginTop: 4, fontWeight: '600', color: '#F97316' },
  actions: {
    flexDirection: 'row',
    marginTop: 4,
    justifyContent: 'space-between',
  },
  button: {
    flex: 1,
    marginRight: 6,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: '#B91C1C',
    alignItems: 'center',
  },
  buttonDisabled: {
    opacity: 0.4,
  },
  buttonText: { color: '#F9FAFB', fontWeight: '600', fontSize: 12 },
  buttonOutline: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#6B7280',
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonOutlineText: {
    fontWeight: '600',
    fontSize: 12,
    color: '#E5E7EB',
  },
});
