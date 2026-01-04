import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';

export default function VenuesScreen() {
  const handlePlaceholder = () => {
    Alert.alert('Coming Soon', 'Venue partners and availability calendars will be integrated here.');
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Venue Booking</Text>
        <Text style={styles.subtitle}>
          Find and reserve spaces for meetings, workshops, launches, and celebrations.
        </Text>

        <Text style={styles.section}>Examples</Text>
        <Text style={styles.item}>• Hotel conference rooms</Text>
        <Text style={styles.item}>• Training centres</Text>
        <Text style={styles.item}>• Community halls & fields</Text>

        <TouchableOpacity style={styles.button} onPress={handlePlaceholder}>
          <Text style={styles.buttonText}>Send Venue Request (MVP)</Text>
        </TouchableOpacity>
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
});
