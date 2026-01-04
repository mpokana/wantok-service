import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';

export default function HireScreen() {
  const handlePlaceholder = () => {
    Alert.alert('Coming Soon', 'Hire requests will be submitted to vetted partners via Supabase.');
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Hire Car & Boats</Text>
        <Text style={styles.subtitle}>
          Long-term vehicles and private boats for business, NGOs, and groups.
        </Text>

        <Text style={styles.section}>Options</Text>
        <Text style={styles.item}>• 4WD hire for highway and rugged routes</Text>
        <Text style={styles.item}>• Sedan / city car hire</Text>
        <Text style={styles.item}>• Private boat hire for island runs</Text>

        <TouchableOpacity style={styles.button} onPress={handlePlaceholder}>
          <Text style={styles.buttonText}>Create Hire Request (MVP)</Text>
        </TouchableOpacity>

        <Text style={styles.note}>
          Later this will connect to vetted operators, pricing in PGK, and approval tracking.
        </Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  content: { padding: 20 },
  title: { fontSize: 22, fontWeight: '700', color: '#FFD700', marginBottom: 4 },
  subtitle: { color: '#FFF', marginBottom: 16 },
  section: { color: '#FFD700', fontWeight: '600', marginTop: 8, marginBottom: 4 },
  item: { color: '#DDD', marginBottom: 4, fontSize: 13 },
  button: {
    marginTop: 16,
    backgroundColor: '#B22222',
    padding: 12,
    borderRadius: 10,
    alignItems: 'center',
  },
  buttonText: { color: '#FFF', fontWeight: '600' },
  note: { color: '#777', fontSize: 11, marginTop: 10 },
});
