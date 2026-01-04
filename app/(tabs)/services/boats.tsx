import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';

export default function BoatsScreen() {
  const handlePlaceholder = () => {
    Alert.alert('Coming Soon', 'Seat booking for coastal and island routes will be added here.');
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Boat & Ship Rides</Text>
        <Text style={styles.subtitle}>
          Plan safe sea travel with registered operators and scheduled routes.
        </Text>

        <Text style={styles.section}>Planned Features</Text>
        <Text style={styles.item}>• PMV dinghy schedules</Text>
        <Text style={styles.item}>• Inter-island ferries & ships</Text>
        <Text style={styles.item}>• Seat reservation & manifests</Text>

        <TouchableOpacity style={styles.button} onPress={handlePlaceholder}>
          <Text style={styles.buttonText}>View Routes (MVP Preview)</Text>
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
