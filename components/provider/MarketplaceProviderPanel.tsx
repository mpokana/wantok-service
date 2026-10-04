import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { supabase } from '../../lib/supabase';

type Props = {
  providerId: string;
};

type ProviderService = {
  id: string;
  category_id: string;
  title: string;
  status: string;
  pricing_model: string;
  service_categories: { name: string; slug: string } | null;
};

type OpenRequest = {
  id: string;
  category_id: string;
  status: string;
  notes: string | null;
  service_address: string | null;
  requested_amount: number | null;
  currency: string;
  created_at: string;
  service_categories: { name: string; slug: string } | null;
};

type Quote = {
  id: string;
  booking_id: string;
  amount: number;
  status: string;
};

export default function MarketplaceProviderPanel({ providerId }: Props) {
  const [services, setServices] = useState<ProviderService[]>([]);
  const [requests, setRequests] = useState<OpenRequest[]>([]);
  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [amounts, setAmounts] = useState<Record<string, string>>({});
  const [messages, setMessages] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);

    const { data: serviceData, error: serviceError } = await supabase
      .from('provider_services')
      .select('id, category_id, title, status, pricing_model, service_categories(name, slug)')
      .eq('provider_id', providerId)
      .order('created_at', { ascending: true });

    if (serviceError) {
      console.log('Provider service load error', serviceError);
      setServices([]);
    } else {
      setServices((serviceData || []) as unknown as ProviderService[]);
    }

    const { data: requestData, error: requestError } = await supabase
      .from('service_bookings')
      .select(`
        id,
        category_id,
        status,
        notes,
        service_address,
        requested_amount,
        currency,
        created_at,
        service_categories(name, slug)
      `)
      .is('provider_id', null)
      .in('status', ['requested', 'quoted'])
      .order('created_at', { ascending: true });

    if (requestError) {
      console.log('Open marketplace request load error', requestError);
      setRequests([]);
    } else {
      const nextRequests = (requestData || []) as unknown as OpenRequest[];
      setRequests(nextRequests);

      if (nextRequests.length) {
        const { data: quoteData } = await supabase
          .from('service_quotes')
          .select('id, booking_id, amount, status')
          .eq('provider_id', providerId)
          .in('booking_id', nextRequests.map((request) => request.id));
        setQuotes((quoteData || []) as Quote[]);
      } else {
        setQuotes([]);
      }
    }

    setLoading(false);
  }, [providerId]);

  useEffect(() => {
    load();
  }, [load]);

  const quoteByBooking = useMemo(() => {
    const map: Record<string, Quote> = {};
    quotes.forEach((quote) => {
      map[quote.booking_id] = quote;
    });
    return map;
  }, [quotes]);

  const genericServices = services.filter(
    (service) => service.service_categories?.slug !== 'taxi-ride',
  );

  const submitForReview = async (service: ProviderService) => {
    setBusyId(service.id);
    try {
      const { error } = await supabase.rpc('submit_provider_service_for_review', {
        p_service_id: service.id,
      });
      if (error) throw error;
      Alert.alert('Submitted', 'Your service listing is now waiting for admin review.');
      await load();
    } catch (error) {
      console.log('Submit provider service review error', error);
      Alert.alert('Could not submit', 'Please check the listing status and try again.');
    } finally {
      setBusyId(null);
    }
  };

  const submitQuote = async (request: OpenRequest) => {
    const rawAmount = amounts[request.id]?.trim() || '';
    const amount = Number(rawAmount.replace(/,/g, ''));
    if (!rawAmount || !Number.isFinite(amount) || amount < 0) {
      Alert.alert('Quote amount required', 'Enter a valid PGK amount.');
      return;
    }

    setBusyId(request.id);
    try {
      const { error } = await supabase.rpc('submit_service_quote', {
        p_booking_id: request.id,
        p_amount: amount,
        p_message: messages[request.id]?.trim() || null,
        p_expires_at: null,
      });
      if (error) throw error;
      Alert.alert('Quote submitted', 'The customer can now review your quote.');
      await load();
    } catch (error) {
      console.log('Submit quote error', error);
      Alert.alert('Could not submit quote', 'Please refresh and try again.');
    } finally {
      setBusyId(null);
    }
  };

  if (loading) {
    return (
      <View style={styles.loadingBox}>
        <ActivityIndicator color="#FACC15" />
      </View>
    );
  }

  return (
    <View style={styles.wrap}>
      <Text style={styles.heading}>Marketplace services</Text>
      <Text style={styles.help}>
        Non-taxi services must be approved before you can receive matching customer requests.
      </Text>

      {!genericServices.length ? (
        <Text style={styles.muted}>
          No non-taxi service listing has been created for this provider yet.
        </Text>
      ) : (
        genericServices.map((service) => (
          <View key={service.id} style={styles.serviceCard}>
            <View style={styles.rowBetween}>
              <Text style={styles.serviceTitle}>
                {service.service_categories?.name || service.title}
              </Text>
              <Text style={styles.status}>{formatStatus(service.status)}</Text>
            </View>
            <Text style={styles.small}>{service.title}</Text>
            {['draft', 'rejected'].includes(service.status) && (
              <TouchableOpacity
                style={styles.reviewButton}
                onPress={() => submitForReview(service)}
                disabled={busyId === service.id}
              >
                <Text style={styles.reviewText}>
                  {busyId === service.id ? 'Submitting…' : 'Submit listing for review'}
                </Text>
              </TouchableOpacity>
            )}
          </View>
        ))
      )}

      <Text style={[styles.heading, { marginTop: 22 }]}>Open requests</Text>
      {!requests.length ? (
        <Text style={styles.muted}>
          No open requests currently match your active approved service listings.
        </Text>
      ) : (
        requests.map((request) => {
          const existingQuote = quoteByBooking[request.id];
          return (
            <View key={request.id} style={styles.requestCard}>
              <View style={styles.rowBetween}>
                <Text style={styles.serviceTitle}>
                  {request.service_categories?.name || 'Service request'}
                </Text>
                <Text style={styles.date}>
                  {new Date(request.created_at).toLocaleDateString()}
                </Text>
              </View>
              {request.notes && <Text style={styles.requestBody}>{request.notes}</Text>}
              {request.service_address && (
                <Text style={styles.small}>Location: {request.service_address}</Text>
              )}
              {request.requested_amount != null && (
                <Text style={styles.small}>
                  Customer budget: {request.currency} {Number(request.requested_amount).toFixed(2)}
                </Text>
              )}

              {existingQuote && (
                <Text style={styles.existingQuote}>
                  Your current quote: PGK {Number(existingQuote.amount).toFixed(2)} ({formatStatus(existingQuote.status)})
                </Text>
              )}

              <TextInput
                style={styles.input}
                value={amounts[request.id] ?? (existingQuote ? String(existingQuote.amount) : '')}
                onChangeText={(value) => setAmounts((prev) => ({ ...prev, [request.id]: value }))}
                placeholder="Quote amount (PGK)"
                placeholderTextColor="#6B7280"
                keyboardType="decimal-pad"
              />
              <TextInput
                style={[styles.input, styles.messageInput]}
                value={messages[request.id] || ''}
                onChangeText={(value) => setMessages((prev) => ({ ...prev, [request.id]: value }))}
                placeholder="Message to customer (optional)"
                placeholderTextColor="#6B7280"
                multiline
              />

              <TouchableOpacity
                style={styles.quoteButton}
                onPress={() => submitQuote(request)}
                disabled={busyId === request.id}
              >
                <Text style={styles.quoteText}>
                  {busyId === request.id
                    ? 'Submitting…'
                    : existingQuote
                      ? 'Update quote'
                      : 'Submit quote'}
                </Text>
              </TouchableOpacity>
            </View>
          );
        })
      )}

      <TouchableOpacity style={styles.refreshButton} onPress={load}>
        <Text style={styles.refreshText}>Refresh marketplace</Text>
      </TouchableOpacity>
    </View>
  );
}

const formatStatus = (status: string) =>
  status.replace(/_/g, ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());

const styles = StyleSheet.create({
  wrap: { marginTop: 18 },
  loadingBox: { paddingVertical: 24, alignItems: 'center' },
  heading: { color: '#FACC15', fontSize: 15, fontWeight: '800', marginBottom: 4 },
  help: { color: '#9CA3AF', fontSize: 11, lineHeight: 16, marginBottom: 9 },
  muted: { color: '#6B7280', fontSize: 11, lineHeight: 16 },
  serviceCard: { backgroundColor: '#0A0A0A', borderWidth: 1, borderColor: '#27272A', borderRadius: 10, padding: 11, marginBottom: 8 },
  requestCard: { backgroundColor: '#0A0A0A', borderWidth: 1, borderColor: '#374151', borderRadius: 10, padding: 11, marginBottom: 10 },
  rowBetween: { flexDirection: 'row', justifyContent: 'space-between', gap: 8 },
  serviceTitle: { color: '#F3F4F6', fontWeight: '700', fontSize: 12, flex: 1 },
  status: { color: '#93C5FD', fontSize: 10, fontWeight: '700' },
  date: { color: '#6B7280', fontSize: 10 },
  small: { color: '#9CA3AF', fontSize: 10, marginTop: 4 },
  requestBody: { color: '#E5E7EB', fontSize: 12, lineHeight: 17, marginTop: 7 },
  existingQuote: { color: '#86EFAC', fontSize: 11, fontWeight: '700', marginTop: 8 },
  input: { marginTop: 8, borderWidth: 1, borderColor: '#374151', borderRadius: 8, backgroundColor: '#111827', color: '#F9FAFB', paddingHorizontal: 10, paddingVertical: 8, fontSize: 12 },
  messageInput: { minHeight: 58, textAlignVertical: 'top' },
  reviewButton: { marginTop: 9, borderWidth: 1, borderColor: '#FACC15', borderRadius: 8, paddingVertical: 7, alignItems: 'center' },
  reviewText: { color: '#FACC15', fontWeight: '700', fontSize: 10 },
  quoteButton: { marginTop: 8, backgroundColor: '#FACC15', borderRadius: 8, paddingVertical: 8, alignItems: 'center' },
  quoteText: { color: '#111827', fontWeight: '800', fontSize: 11 },
  refreshButton: { marginTop: 6, paddingVertical: 10, alignItems: 'center' },
  refreshText: { color: '#FACC15', fontSize: 11, fontWeight: '700' },
});
