import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { supabase } from '../../lib/supabase';
import { useAuthProfile } from '../../hooks/useAuthProfile';

type ProviderApplication = {
  id: string;
  user_id: string;
  service_type: string | null;
  company_name: string | null;
  vehicle_plate: string | null;
  vehicle_make: string | null;
  vehicle_model: string | null;
  vehicle_color: string | null;
  id_photo_url: string | null;
  license_photo_url: string | null;
  notes: string | null;
  status: string;
  created_at: string;
};

export default function AdminScreen() {
  const { profile, loading: profileLoading } = useAuthProfile();
  const [loading, setLoading] = useState(true);
  const [items, setItems] = useState<ProviderApplication[]>([]);
  const [busyId, setBusyId] = useState<string | null>(null);

  useEffect(() => {
    if (!profile?.is_admin) return;
    loadPending();
  }, [profile?.is_admin]);

  const loadPending = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('provider_applications')
      .select('*')
      .eq('status', 'pending')
      .order('created_at', { ascending: true });

    if (error) {
      console.log('Load applications error', error);
      Alert.alert('Error', 'Could not load applications.');
    } else {
      setItems((data || []) as ProviderApplication[]);
    }
    setLoading(false);
  };

  const handleApprove = async (application: ProviderApplication) => {
    try {
      setBusyId(application.id);

      const { error } = await supabase.rpc('review_provider_application', {
        p_application_id: application.id,
        p_decision: 'approved',
      });

      if (error) throw error;

      Alert.alert('Approved', 'Application has been approved.');
      setItems(prev => prev.filter(a => a.id !== application.id));
    } catch (err: any) {
      console.log('Approve error', err);
      Alert.alert('Error', 'Could not approve this application.');
    } finally {
      setBusyId(null);
    }
  };

  const handleReject = async (application: ProviderApplication) => {
    try {
      setBusyId(application.id);

      const { error } = await supabase.rpc('review_provider_application', {
        p_application_id: application.id,
        p_decision: 'rejected',
      });

      if (error) throw error;

      Alert.alert('Rejected', 'Application has been rejected.');
      setItems(prev => prev.filter(a => a.id !== application.id));
    } catch (err: any) {
      console.log('Reject error', err);
      Alert.alert('Error', 'Could not reject this application.');
    } finally {
      setBusyId(null);
    }
  };

  if (profileLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#FACC15" />
      </View>
    );
  }

  if (!profile?.is_admin) {
    return (
      <View style={styles.container}>
        <Text style={styles.title}>Admin</Text>
        <Text style={styles.text}>
          You do not have admin access on this account.
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Admin – Provider Applications</Text>

      {loading ? (
        <View style={styles.center}>
          <ActivityIndicator color="#FACC15" />
        </View>
      ) : items.length === 0 ? (
        <Text style={styles.text}>No pending applications.</Text>
      ) : (
        <FlatList
          data={items}
          keyExtractor={item => item.id}
          contentContainerStyle={{ paddingBottom: 24 }}
          renderItem={({ item }) => {
            const waiting = busyId === item.id;
            return (
              <View style={styles.card}>
                <Text style={styles.cardTitle}>
                  {item.company_name || 'Individual'}
                </Text>
                <Text style={styles.cardSub}>
                  Type: {item.service_type || 'Unknown'}
                </Text>
                {item.vehicle_plate && (
                  <Text style={styles.cardSub}>
                    Vehicle: {item.vehicle_plate} {item.vehicle_make}{' '}
                    {item.vehicle_model} {item.vehicle_color}
                  </Text>
                )}
                {item.notes && (
                  <Text style={styles.cardNotes}>
                    Notes: {item.notes}
                  </Text>
                )}

                <View style={styles.row}>
                  <TouchableOpacity
                    style={[
                      styles.approveButton,
                      waiting && { opacity: 0.6 },
                    ]}
                    onPress={() => handleApprove(item)}
                    disabled={waiting}
                  >
                    <Text style={styles.approveText}>
                      {waiting
                        ? 'Working...'
                        : 'Approve & make provider'}
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={[
                      styles.rejectButton,
                      waiting && { opacity: 0.6 },
                    ]}
                    onPress={() => handleReject(item)}
                    disabled={waiting}
                  >
                    <Text style={styles.rejectText}>Reject</Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
          }}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  center: {
    flex: 1,
    backgroundColor: '#000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    flex: 1,
    backgroundColor: '#000',
    padding: 16,
    paddingTop: 48,
  },
  title: {
    fontSize: 20,
    color: '#FACC15',
    fontWeight: '700',
    marginBottom: 10,
  },
  text: {
    color: '#E5E7EB',
    fontSize: 14,
  },
  card: {
    marginBottom: 10,
    padding: 12,
    borderRadius: 10,
    backgroundColor: '#050505',
    borderWidth: 1,
    borderColor: '#27272A',
  },
  cardTitle: {
    color: '#FACC15',
    fontSize: 15,
    fontWeight: '600',
  },
  cardSub: {
    color: '#D1D5DB',
    fontSize: 12,
    marginTop: 2,
  },
  cardNotes: {
    color: '#9CA3AF',
    fontSize: 11,
    marginTop: 4,
  },
  row: {
    flexDirection: 'row',
    marginTop: 10,
    justifyContent: 'space-between',
  },
  approveButton: {
    flex: 1,
    marginRight: 6,
    backgroundColor: '#22C55E',
    paddingVertical: 8,
    borderRadius: 8,
    alignItems: 'center',
  },
  approveText: {
    color: '#020817',
    fontWeight: '700',
    fontSize: 11,
  },
  rejectButton: {
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#F97316',
    alignItems: 'center',
    justifyContent: 'center',
  },
  rejectText: {
    color: '#F97316',
    fontWeight: '600',
    fontSize: 11,
  },
});
