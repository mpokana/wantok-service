import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';

export default function EventsScreen() {
  const handlePlaceholder = () => {
    Alert.alert(
      'Coming Soon',
      'Events will be loaded from Supabase so users can browse and book directly.'
    );
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Upcoming Events</Text>
        <Text style={styles.subtitle}>
          Highlight key events around PNG: sports, music, conferences, church programs, and more.
        </Text>

        <Text style={styles.section}>Planned Features</Text>
        <Text style={styles.item}>• Curated event list with locations</Text>
        <Text style={styles.item}>• Ticket / seat reservation</Text>
        <Text style={styles.item}>• Integration with taxi and venue booking flows</Text>

        <TouchableOpacity style={styles.button} onPress={handlePlaceholder}>
          <Text style={styles.buttonText}>View Sample Events (MVP)</Text>
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
