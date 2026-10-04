import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  ScrollView,
} from 'react-native';
import { supabase } from '../../lib/supabase';
import { useAuthProfile } from '../../hooks/useAuthProfile';


type Application = {
  id: string;
  status: 'pending' | 'approved' | 'rejected';
  service_type: string;
  created_at: string;
};

const SERVICE_TYPES = [
  { value: 'driver', label: 'Taxi / Private Driver' },
  { value: 'delivery', label: 'Delivery / Courier' },
  { value: 'specialist', label: 'Specialist / Trade Service' },
  { value: 'general_labour', label: 'General Labour / People for Hire' },
  { value: 'vehicle_hire', label: 'Vehicle Hire' },
  { value: 'boat_hire', label: 'Private Boat Hire' },
  { value: 'boat_operator', label: 'Boat / Ship Passenger Service' },
  { value: 'venue', label: 'Venue / Space Provider' },
  { value: 'events', label: 'Event Organiser' },
  { value: 'food_vendor', label: 'Food Vendor / Restaurant' },
  { value: 'shop', label: 'Shop / Grocery Merchant' },
];

export default function BecomeProviderScreen() {
  const { profile, loading: profileLoading } = useAuthProfile();

  const [serviceType, setServiceType] = useState('driver');
  const [companyName, setCompanyName] = useState('');
  const [vehiclePlate, setVehiclePlate] = useState('');
  const [vehicleMake, setVehicleMake] = useState('');
  const [vehicleModel, setVehicleModel] = useState('');
  const [vehicleColor, setVehicleColor] = useState('');
  const [idUrl, setIdUrl] = useState('');
  const [licenceUrl, setLicenceUrl] = useState('');
  const [notes, setNotes] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [existingApp, setExistingApp] = useState<Application | null>(null);
  const [loadingApp, setLoadingApp] = useState(true);

  useEffect(() => {
    const loadExisting = async () => {
      if (!profile?.id) {
        setExistingApp(null);
        setLoadingApp(false);
        return;
      }

      const { data, error } = await supabase
        .from('provider_applications')
        .select('id, status, service_type, created_at')
        .eq('user_id', profile.id)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (error) {
        console.log('Error loading provider_applications', error);
      }

      setExistingApp(data || null);
      setLoadingApp(false);
    };

    if (!profileLoading) {
      loadExisting();
    }
  }, [profile?.id, profileLoading]);

  const handleSubmit = async () => {
    if (!profile?.id) {
      Alert.alert('Sign in required', 'Please sign in to apply as a provider.');
      return;
    }

    if (!serviceType) {
      Alert.alert(
        'Missing information',
        'Please select the type of service you want to provide.'
      );
      return;
    }

    if (
      serviceType === 'driver' &&
      (!vehiclePlate || !licenceUrl || !idUrl)
    ) {
      Alert.alert(
        'Missing information',
        'For drivers, please provide plate number, ID and licence document URLs.'
      );
      return;
    }

    setSubmitting(true);

    const { error } = await supabase.from('provider_applications').insert([
      {
        user_id: profile.id,
        service_type: serviceType,
        company_name: companyName || null,
        vehicle_plate: vehiclePlate || null,
        vehicle_make: vehicleMake || null,
        vehicle_model: vehicleModel || null,
        vehicle_color: vehicleColor || null,
        id_photo_url: idUrl || null,
        license_photo_url: licenceUrl || null,
        notes: notes || null,
      },
    ]);

    setSubmitting(false);

    if (error) {
      console.log(error);
      Alert.alert(
        'Error',
        'Could not submit your application. Please try again.'
      );
      return;
    }

    Alert.alert(
      'Application submitted',
      'Your application has been received. Wantok Service Support will review and update your status.'
    );

    const { data } = await supabase
      .from('provider_applications')
      .select('id, status, service_type, created_at')
      .eq('user_id', profile.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    setExistingApp(data || null);
  };

  if (profileLoading || loadingApp) {
    return (
      <View style={styles.center}>
        <ActivityIndicator />
        <Text>Loading...</Text>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Become a Wantok Service Provider</Text>
      <Text style={styles.subtitle}>
        Apply to offer transport, delivery, skilled work, labour, hire,
        venues, events, food or retail services through Wantok Service. All
        applications are manually reviewed for safety and quality.
      </Text>

      {existingApp && (
        <View style={styles.statusBox}>
          <Text style={styles.statusTitle}>Your latest application</Text>
          <Text>Type: {existingApp.service_type}</Text>
          <Text>Status: {existingApp.status}</Text>
          <Text style={styles.statusNote}>
            You can submit updated information below if something has changed.
          </Text>
        </View>
      )}

      <Text style={styles.label}>Service type</Text>
      <View style={styles.chipRow}>
        {SERVICE_TYPES.map((s) => (
          <TouchableOpacity
            key={s.value}
            style={[
              styles.chip,
              serviceType === s.value && styles.chipActive,
            ]}
            onPress={() => setServiceType(s.value)}
          >
            <Text
              style={[
                styles.chipText,
                serviceType === s.value && styles.chipTextActive,
              ]}
            >
              {s.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.label}>Business / Display name (optional)</Text>
      <TextInput
        style={styles.input}
        placeholder="e.g. Lae City Taxi, POM Food Express"
        value={companyName}
        onChangeText={setCompanyName}
      />

      {serviceType === 'driver' && (
        <>
          <Text style={styles.sectionTitle}>Vehicle details</Text>
          <TextInput
            style={styles.input}
            placeholder="Plate number (rego)"
            value={vehiclePlate}
            onChangeText={setVehiclePlate}
          />
          <TextInput
            style={styles.input}
            placeholder="Make (e.g. Toyota)"
            value={vehicleMake}
            onChangeText={setVehicleMake}
          />
          <TextInput
            style={styles.input}
            placeholder="Model (e.g. Corolla)"
            value={vehicleModel}
            onChangeText={setVehicleModel}
          />
          <TextInput
            style={styles.input}
            placeholder="Colour"
            value={vehicleColor}
            onChangeText={setVehicleColor}
          />

          <Text style={styles.sectionTitle}>
            Documents (temporary URL fields)
          </Text>
          <TextInput
            style={styles.input}
            placeholder="ID photo URL"
            value={idUrl}
            onChangeText={setIdUrl}
          />
          <TextInput
            style={styles.input}
            placeholder="Driver licence URL"
            value={licenceUrl}
            onChangeText={setLicenceUrl}
          />
        </>
      )}

      <Text style={styles.label}>Notes (optional)</Text>
      <TextInput
        style={[styles.input, styles.textarea]}
        placeholder="Tell us more about your service, coverage area, etc."
        value={notes}
        onChangeText={setNotes}
        multiline
      />

      <TouchableOpacity
        style={styles.submitBtn}
        onPress={handleSubmit}
        disabled={submitting}
      >
        {submitting ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.submitText}>Submit application</Text>
        )}
      </TouchableOpacity>

      <Text style={styles.footerNote}>
        Wantok Service Support will verify your details. Once approved, a Provider Hub tab will
        appear in your app with tools to accept jobs and manage your services.
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    padding: 16,
    paddingBottom: 32,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: { fontSize: 20, fontWeight: '700', marginBottom: 8 },
  subtitle: { fontSize: 13, marginBottom: 16, color: '#444' },
  label: { marginTop: 12, fontSize: 13, fontWeight: '600' },
  sectionTitle: { marginTop: 18, fontSize: 15, fontWeight: '700' },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 8,
    marginTop: 6,
    fontSize: 14,
  },
  textarea: {
    minHeight: 70,
    textAlignVertical: 'top',
  },
  chipRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 6,
  },
  chip: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#ccc',
    marginRight: 6,
    marginBottom: 6,
  },
  chipActive: {
    backgroundColor: '#111',
    borderColor: '#111',
  },
  chipText: { fontSize: 12 },
  chipTextActive: { color: '#fff' },
  submitBtn: {
    marginTop: 20,
    backgroundColor: '#111',
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  submitText: { color: '#fff', fontWeight: '600', fontSize: 15 },
  statusBox: {
    padding: 10,
    backgroundColor: '#f4f4f4',
    borderRadius: 8,
    marginBottom: 8,
  },
  statusTitle: { fontWeight: '700', marginBottom: 2 },
  statusNote: { fontSize: 11, color: '#555', marginTop: 2 },
  footerNote: {
    marginTop: 10,
    fontSize: 11,
    color: '#666',
  },
});
