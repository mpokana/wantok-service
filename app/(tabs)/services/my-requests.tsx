import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useAuthProfile } from '../../../hooks/useAuthProfile';
import { supabase } from '../../../lib/supabase';

type Booking = {
  id: string;
  status: string;
  notes: string | null;
  service_address: string | null;
  requested_amount: number | null;
  quoted_amount: number | null;
  currency: string;
  created_at: string;
  provider_id: string | null;
  service_categories: { name: string; slug: string } | null;
};

type Quote = {
  id: string;
  booking_id: string;
  provider_id: string;
  amount: number;
  currency: string;
  message: string | null;
  status: string;
  created_at: string;
};

export default function MyServiceRequestsScreen() {
  const { session, loading: authLoading } = useAuthProfile();
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [providerNames, setProviderNames] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  const loadData = useCallback(async () => {
    if (!session?.user) {
      setBookings([]);
      setQuotes([]);
      setLoading(false);
      return;
    }

    const { data: bookingData, error: bookingError } = await supabase
      .from('service_bookings')
      .select(`
        id,
        status,
        notes,
        service_address,
        requested_amount,
        quoted_amount,
        currency,
        created_at,
        provider_id,
        service_categories(name, slug)
      `)
      .eq('customer_id', session.user.id)
      .order('created_at', { ascending: false });

    if (bookingError) {
      console.log('Load service bookings error', bookingError);
      Alert.alert('Error', 'Could not load your service requests.');
      setLoading(false);
      return;
    }

    const nextBookings = (bookingData || []) as unknown as Booking[];
    setBookings(nextBookings);

    const bookingIds = nextBookings.map((booking) => booking.id);
    if (!bookingIds.length) {
      setQuotes([]);
      setProviderNames({});
      setLoading(false);
      return;
    }

    const { data: quoteData, error: quoteError } = await supabase
      .from('service_quotes')
      .select('id, booking_id, provider_id, amount, currency, message, status, created_at')
      .in('booking_id', bookingIds)
      .order('created_at', { ascending: false });

    if (quoteError) {
      console.log('Load service quotes error', quoteError);
      setQuotes([]);
    } else {
      const nextQuotes = (quoteData || []) as Quote[];
      setQuotes(nextQuotes);

      const providerIds = [...new Set(nextQuotes.map((quote) => quote.provider_id))];
      if (providerIds.length) {
        const { data: providers } = await supabase
          .from('provider_profiles')
          .select('provider_id, display_name')
          .in('provider_id', providerIds);

        const names: Record<string, string> = {};
        (providers || []).forEach((provider: any) => {
          names[provider.provider_id] = provider.display_name;
        });
        setProviderNames(names);
      } else {
        setProviderNames({});
      }
    }

    setLoading(false);
  }, [session?.user]);

  useEffect(() => {
    if (!authLoading) loadData();
  }, [authLoading, loadData]);

  const quotesByBooking = useMemo(() => {
    const grouped: Record<string, Quote[]> = {};
    quotes.forEach((quote) => {
      if (!grouped[quote.booking_id]) grouped[quote.booking_id] = [];
      grouped[quote.booking_id].push(quote);
    });
    return grouped;
  }, [quotes]);

  const refresh = async () => {
    setRefreshing(true);
    await loadData();
    setRefreshing(false);
  };

  const acceptQuote = async (quote: Quote) => {
    setBusyId(quote.id);
    try {
      const { error } = await supabase.rpc('accept_service_quote', {
        p_quote_id: quote.id,
      });
      if (error) throw error;
      Alert.alert('Quote accepted', 'The provider has been assigned to your request.');
      await loadData();
    } catch (error) {
      console.log('Accept quote error', error);
      Alert.alert('Could not accept quote', 'Please refresh and try again.');
    } finally {
      setBusyId(null);
    }
  };

  const cancelBooking = async (booking: Booking) => {
    setBusyId(booking.id);
    try {
      const { error } = await supabase.rpc('cancel_service_booking', {
        p_booking_id: booking.id,
      });
      if (error) throw error;
      await loadData();
    } catch (error) {
      console.log('Cancel booking error', error);
      Alert.alert('Could not cancel request', 'The request may already be in progress.');
    } finally {
      setBusyId(null);
    }
  };

  const canCancel = (status: string) =>
    ['requested', 'quoted', 'accepted', 'confirmed'].includes(status);

  if (authLoading || loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#FACC15" />
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={refresh} />}
    >
      <Text style={styles.title}>My Service Requests</Text>
      <Text style={styles.subtitle}>Requests, provider quotes and confirmed non-taxi services.</Text>

      {!bookings.length && (
        <View style={styles.emptyBox}>
          <Text style={styles.muted}>You have not posted any marketplace requests yet.</Text>
        </View>
      )}

      {bookings.map((booking) => {
        const bookingQuotes = quotesByBooking[booking.id] || [];
        return (
          <View key={booking.id} style={styles.card}>
            <View style={styles.rowBetween}>
              <Text style={styles.cardTitle}>
                {booking.service_categories?.name || 'Service request'}
              </Text>
              <Text style={styles.status}>{formatStatus(booking.status)}</Text>
            </View>

            <Text style={styles.date}>{new Date(booking.created_at).toLocaleString()}</Text>
            {booking.notes && <Text style={styles.body}>{booking.notes}</Text>}
            {booking.service_address && (
              <Text style={styles.meta}>Location: {booking.service_address}</Text>
            )}
            {booking.requested_amount != null && (
              <Text style={styles.meta}>Your budget: {booking.currency} {Number(booking.requested_amount).toFixed(2)}</Text>
            )}

            {!!bookingQuotes.length && (
              <View style={styles.quotesWrap}>
                <Text style={styles.sectionTitle}>Quotes</Text>
                {bookingQuotes.map((quote) => (
                  <View key={quote.id} style={styles.quoteCard}>
                    <View style={styles.rowBetween}>
                      <Text style={styles.quoteProvider}>
                        {providerNames[quote.provider_id] || 'Verified provider'}
                      </Text>
                      <Text style={styles.quoteAmount}>
                        {quote.currency} {Number(quote.amount).toFixed(2)}
                      </Text>
                    </View>
                    {quote.message && <Text style={styles.quoteMessage}>{quote.message}</Text>}
                    <Text style={styles.quoteStatus}>{formatStatus(quote.status)}</Text>

                    {quote.status === 'pending' && ['requested', 'quoted'].includes(booking.status) && (
                      <TouchableOpacity
                        style={styles.acceptButton}
                        onPress={() => acceptQuote(quote)}
                        disabled={busyId === quote.id}
                      >
                        <Text style={styles.acceptText}>
                          {busyId === quote.id ? 'Accepting…' : 'Accept quote'}
                        </Text>
                      </TouchableOpacity>
                    )}
                  </View>
                ))}
              </View>
            )}

            {canCancel(booking.status) && (
              <TouchableOpacity
                style={styles.cancelButton}
                onPress={() =>
                  Alert.alert('Cancel request', 'Cancel this service request?', [
                    { text: 'Keep request' },
                    { text: 'Cancel request', style: 'destructive', onPress: () => cancelBooking(booking) },
                  ])
                }
                disabled={busyId === booking.id}
              >
                <Text style={styles.cancelText}>
                  {busyId === booking.id ? 'Cancelling…' : 'Cancel request'}
                </Text>
              </TouchableOpacity>
            )}
          </View>
        );
      })}
    </ScrollView>
  );
}

const formatStatus = (status: string) =>
  status.replace(/_/g, ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());

const styles = StyleSheet.create({
  center: { flex: 1, backgroundColor: '#000', alignItems: 'center', justifyContent: 'center' },
  container: { flex: 1, backgroundColor: '#000' },
  content: { padding: 16, paddingBottom: 40 },
  title: { color: '#FACC15', fontSize: 22, fontWeight: '800' },
  subtitle: { color: '#9CA3AF', fontSize: 12, marginTop: 3, marginBottom: 14 },
  emptyBox: { borderWidth: 1, borderColor: '#27272A', borderRadius: 10, padding: 16 },
  muted: { color: '#9CA3AF', fontSize: 12 },
  card: { backgroundColor: '#080808', borderWidth: 1, borderColor: '#27272A', borderRadius: 12, padding: 13, marginBottom: 12 },
  rowBetween: { flexDirection: 'row', justifyContent: 'space-between', gap: 8 },
  cardTitle: { color: '#FACC15', fontWeight: '700', fontSize: 14, flex: 1 },
  status: { color: '#93C5FD', fontSize: 11, fontWeight: '700' },
  date: { color: '#6B7280', fontSize: 10, marginTop: 3 },
  body: { color: '#E5E7EB', fontSize: 13, lineHeight: 18, marginTop: 9 },
  meta: { color: '#9CA3AF', fontSize: 11, marginTop: 5 },
  quotesWrap: { marginTop: 12 },
  sectionTitle: { color: '#FACC15', fontWeight: '700', fontSize: 12, marginBottom: 6 },
  quoteCard: { backgroundColor: '#111827', borderRadius: 9, padding: 10, marginBottom: 7 },
  quoteProvider: { color: '#F9FAFB', fontWeight: '700', fontSize: 12 },
  quoteAmount: { color: '#86EFAC', fontWeight: '800', fontSize: 12 },
  quoteMessage: { color: '#D1D5DB', fontSize: 11, marginTop: 5 },
  quoteStatus: { color: '#9CA3AF', fontSize: 10, marginTop: 5 },
  acceptButton: { marginTop: 8, backgroundColor: '#FACC15', paddingVertical: 8, borderRadius: 8, alignItems: 'center' },
  acceptText: { color: '#111827', fontWeight: '800', fontSize: 11 },
  cancelButton: { marginTop: 10, borderWidth: 1, borderColor: '#7F1D1D', borderRadius: 8, paddingVertical: 8, alignItems: 'center' },
  cancelText: { color: '#F87171', fontWeight: '700', fontSize: 11 },
});
