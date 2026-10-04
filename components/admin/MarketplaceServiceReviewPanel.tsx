import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { supabase } from '../../lib/supabase';

type PendingService = {
  id: string;
  provider_id: string;
  category_id: string;
  title: string;
  description: string | null;
  pricing_model: string;
  base_price: number | null;
  currency: string;
  status: string;
  created_at: string;
};

type Props = {
  enabled: boolean;
};

export default function MarketplaceServiceReviewPanel({ enabled }: Props) {
  const [items, setItems] = useState<PendingService[]>([]);
  const [providerNames, setProviderNames] = useState<Record<string, string>>({});
  const [categoryNames, setCategoryNames] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!enabled) return;
    setLoading(true);

    const { data, error } = await supabase
      .from('provider_services')
      .select('id, provider_id, category_id, title, description, pricing_model, base_price, currency, status, created_at')
      .eq('status', 'pending_review')
      .order('created_at', { ascending: true });

    if (error) {
      console.log('Admin provider service load error', error);
      setItems([]);
      setLoading(false);
      return;
    }

    const next = (data || []) as PendingService[];
    setItems(next);

    const providerIds = [...new Set(next.map((item) => item.provider_id))];
    const categoryIds = [...new Set(next.map((item) => item.category_id))];

    if (providerIds.length) {
      const { data: providers } = await supabase
        .from('provider_profiles')
        .select('provider_id, display_name')
        .in('provider_id', providerIds);
      const map: Record<string, string> = {};
      (providers || []).forEach((provider: any) => {
        map[provider.provider_id] = provider.display_name;
      });
      setProviderNames(map);
    } else {
      setProviderNames({});
    }

    if (categoryIds.length) {
      const { data: categories } = await supabase
        .from('service_categories')
        .select('id, name')
        .in('id', categoryIds);
      const map: Record<string, string> = {};
      (categories || []).forEach((category: any) => {
        map[category.id] = category.name;
      });
      setCategoryNames(map);
    } else {
      setCategoryNames({});
    }

    setLoading(false);
  }, [enabled]);

  useEffect(() => {
    load();
  }, [load]);

  const review = async (item: PendingService, status: 'active' | 'rejected') => {
    setBusyId(item.id);
    try {
      const { error } = await supabase.rpc('admin_set_provider_service_status', {
        p_service_id: item.id,
        p_status: status,
      });
      if (error) throw error;
      setItems((prev) => prev.filter((service) => service.id !== item.id));
    } catch (error) {
      console.log('Admin provider service review error', error);
      Alert.alert('Review failed', 'Could not update this provider service.');
    } finally {
      setBusyId(null);
    }
  };

  if (!enabled) return null;

  return (
    <View style={styles.wrap}>
      <View style={styles.headingRow}>
        <Text style={styles.heading}>Marketplace service reviews</Text>
        <TouchableOpacity onPress={load}>
          <Text style={styles.refresh}>Refresh</Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <ActivityIndicator color="#FACC15" style={{ marginVertical: 12 }} />
      ) : !items.length ? (
        <Text style={styles.muted}>No provider service listings are waiting for review.</Text>
      ) : (
        items.map((item) => {
          const waiting = busyId === item.id;
          return (
            <View key={item.id} style={styles.card}>
              <Text style={styles.title}>{item.title}</Text>
              <Text style={styles.meta}>
                Provider: {providerNames[item.provider_id] || item.provider_id.slice(0, 8)}
              </Text>
              <Text style={styles.meta}>
                Category: {categoryNames[item.category_id] || 'Unknown'}
              </Text>
              <Text style={styles.meta}>Pricing: {item.pricing_model}</Text>
              {item.base_price != null && (
                <Text style={styles.meta}>
                  Base price: {item.currency} {Number(item.base_price).toFixed(2)}
                </Text>
              )}
              {item.description && <Text style={styles.description}>{item.description}</Text>}

              <View style={styles.row}>
                <TouchableOpacity
                  style={styles.approveButton}
                  onPress={() => review(item, 'active')}
                  disabled={waiting}
                >
                  <Text style={styles.approveText}>{waiting ? 'Working…' : 'Approve'}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.rejectButton}
                  onPress={() => review(item, 'rejected')}
                  disabled={waiting}
                >
                  <Text style={styles.rejectText}>Reject</Text>
                </TouchableOpacity>
              </View>
            </View>
          );
        })
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: 22 },
  headingRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  heading: { color: '#FACC15', fontSize: 15, fontWeight: '800' },
  refresh: { color: '#93C5FD', fontSize: 11, fontWeight: '700' },
  muted: { color: '#9CA3AF', fontSize: 11, marginTop: 8 },
  card: { marginTop: 9, padding: 11, borderRadius: 10, backgroundColor: '#080808', borderWidth: 1, borderColor: '#374151' },
  title: { color: '#F3F4F6', fontWeight: '700', fontSize: 13 },
  meta: { color: '#9CA3AF', fontSize: 10, marginTop: 3 },
  description: { color: '#D1D5DB', fontSize: 11, lineHeight: 16, marginTop: 6 },
  row: { flexDirection: 'row', marginTop: 10, gap: 8 },
  approveButton: { flex: 1, backgroundColor: '#22C55E', paddingVertical: 8, borderRadius: 8, alignItems: 'center' },
  approveText: { color: '#052E16', fontWeight: '800', fontSize: 11 },
  rejectButton: { paddingHorizontal: 16, borderWidth: 1, borderColor: '#F97316', borderRadius: 8, justifyContent: 'center' },
  rejectText: { color: '#F97316', fontWeight: '700', fontSize: 11 },
});
