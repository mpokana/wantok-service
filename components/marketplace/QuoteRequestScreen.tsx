import { useRouter } from 'expo-router';
import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { useAuthProfile } from '../../hooks/useAuthProfile';
import { supabase } from '../../lib/supabase';

type Props = {
  categorySlug: string;
  title: string;
  subtitle: string;
  examples: string[];
  requestLabel?: string;
};

type ServiceCategory = {
  id: string;
  name: string;
};

export default function QuoteRequestScreen({
  categorySlug,
  title,
  subtitle,
  examples,
  requestLabel = 'Post request',
}: Props) {
  const router = useRouter();
  const { session, loading: authLoading } = useAuthProfile();
  const [category, setCategory] = useState<ServiceCategory | null>(null);
  const [loadingCategory, setLoadingCategory] = useState(true);
  const [details, setDetails] = useState('');
  const [address, setAddress] = useState('');
  const [budget, setBudget] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    const loadCategory = async () => {
      const { data, error } = await supabase
        .from('service_categories')
        .select('id, name')
        .eq('slug', categorySlug)
        .eq('is_active', true)
        .maybeSingle();

      if (error) {
        console.log('Category load error', error);
      }

      setCategory((data as ServiceCategory | null) ?? null);
      setLoadingCategory(false);
    };

    loadCategory();
  }, [categorySlug]);

  const handleSubmit = async () => {
    if (!session?.user) {
      Alert.alert('Sign in required', 'Please sign in before posting a request.');
      return;
    }

    if (!category) {
      Alert.alert('Unavailable', 'This service category is not available right now.');
      return;
    }

    if (details.trim().length < 10) {
      Alert.alert('More detail needed', 'Please describe the work you need in a little more detail.');
      return;
    }

    let requestedAmount: number | null = null;
    if (budget.trim()) {
      requestedAmount = Number(budget.replace(/,/g, ''));
      if (!Number.isFinite(requestedAmount) || requestedAmount < 0) {
        Alert.alert('Invalid budget', 'Enter a valid PGK amount or leave the budget blank.');
        return;
      }
    }

    setSubmitting(true);
    try {
      const { error } = await supabase.from('service_bookings').insert({
        customer_id: session.user.id,
        category_id: category.id,
        service_address: address.trim() || null,
        notes: details.trim(),
        requested_amount: requestedAmount,
        currency: 'PGK',
      });

      if (error) throw error;

      Alert.alert(
        'Request posted',
        'Approved providers for this service can now review your request and submit a quote.',
        [{ text: 'View my requests', onPress: () => router.push('/services/my-requests') }],
      );

      setDetails('');
      setAddress('');
      setBudget('');
    } catch (error) {
      console.log('Service request error', error);
      Alert.alert('Could not post request', 'Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  if (authLoading || loadingCategory) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#FACC15" />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.subtitle}>{subtitle}</Text>

      <Text style={styles.section}>Examples</Text>
      {examples.map((example) => (
        <Text key={example} style={styles.example}>• {example}</Text>
      ))}

      <Text style={styles.section}>What do you need?</Text>
      <TextInput
        style={[styles.input, styles.multiline]}
        value={details}
        onChangeText={setDetails}
        placeholder="Describe the job, scope, timing, skills or other requirements"
        placeholderTextColor="#6B7280"
        multiline
        maxLength={2000}
      />

      <Text style={styles.label}>Location / area</Text>
      <TextInput
        style={styles.input}
        value={address}
        onChangeText={setAddress}
        placeholder="e.g. Lae, Eriku or project site details"
        placeholderTextColor="#6B7280"
        maxLength={300}
      />

      <Text style={styles.label}>Indicative budget in PGK (optional)</Text>
      <TextInput
        style={styles.input}
        value={budget}
        onChangeText={setBudget}
        placeholder="e.g. 500"
        placeholderTextColor="#6B7280"
        keyboardType="decimal-pad"
        maxLength={14}
      />

      <View style={styles.infoBox}>
        <Text style={styles.infoTitle}>How quoting works</Text>
        <Text style={styles.infoText}>
          Only verified providers with an approved service listing in this category can see open requests and quote. You choose whether to accept a quote.
        </Text>
      </View>

      <TouchableOpacity
        style={[styles.button, submitting && styles.buttonDisabled]}
        onPress={handleSubmit}
        disabled={submitting || !category}
      >
        {submitting ? (
          <ActivityIndicator color="#111827" />
        ) : (
          <Text style={styles.buttonText}>{requestLabel}</Text>
        )}
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.secondaryButton}
        onPress={() => router.push('/services/my-requests')}
      >
        <Text style={styles.secondaryText}>View my service requests</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, backgroundColor: '#000', alignItems: 'center', justifyContent: 'center' },
  container: { flex: 1, backgroundColor: '#000' },
  content: { padding: 20, paddingBottom: 44 },
  title: { color: '#FACC15', fontSize: 22, fontWeight: '800', marginBottom: 4 },
  subtitle: { color: '#E5E7EB', fontSize: 13, lineHeight: 19, marginBottom: 18 },
  section: { color: '#FACC15', fontWeight: '700', marginTop: 8, marginBottom: 7 },
  example: { color: '#D1D5DB', fontSize: 13, marginBottom: 5 },
  label: { color: '#E5E7EB', fontSize: 12, fontWeight: '600', marginTop: 12, marginBottom: 5 },
  input: {
    borderWidth: 1,
    borderColor: '#374151',
    backgroundColor: '#0B0B0B',
    color: '#F9FAFB',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
  },
  multiline: { minHeight: 115, textAlignVertical: 'top' },
  infoBox: {
    marginTop: 16,
    padding: 12,
    borderWidth: 1,
    borderColor: '#374151',
    backgroundColor: '#111827',
    borderRadius: 10,
  },
  infoTitle: { color: '#FACC15', fontWeight: '700', marginBottom: 4 },
  infoText: { color: '#D1D5DB', fontSize: 12, lineHeight: 17 },
  button: {
    marginTop: 18,
    backgroundColor: '#FACC15',
    borderRadius: 10,
    paddingVertical: 13,
    alignItems: 'center',
  },
  buttonDisabled: { opacity: 0.55 },
  buttonText: { color: '#111827', fontWeight: '800', fontSize: 14 },
  secondaryButton: { marginTop: 10, alignItems: 'center', paddingVertical: 10 },
  secondaryText: { color: '#FACC15', fontWeight: '600', fontSize: 12 },
});
