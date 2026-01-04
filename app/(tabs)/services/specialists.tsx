import { View, Text, StyleSheet, ScrollView, TouchableOpacity, Alert } from 'react-native';

export default function SpecialistsScreen() {
  const handlePlaceholder = () => {
    Alert.alert(
      'Coming Soon',
      'Specialist requests will be matched with verified professionals via Supabase.'
    );
  };

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Hire Specialist Service</Text>
        <Text style={styles.subtitle}>
          Find trusted experts for projects, events, and operations across PNG.
        </Text>

        <Text style={styles.section}>Example Specialist Categories</Text>
        <Text style={styles.item}>• Electrical & solar technicians</Text>
        <Text style={styles.item}>• ICT & networking support</Text>
        <Text style={styles.item}>• Drivers & logistics coordinators</Text>
        <Text style={styles.item}>• Tour guides & translators</Text>
        <Text style={styles.item}>• Trainers, consultants & facilitators</Text>
        <Text style={styles.item}>• Security & event staff</Text>

        <TouchableOpacity style={styles.button} onPress={handlePlaceholder}>
          <Text style={styles.buttonText}>Create Specialist Request (MVP)</Text>
        </TouchableOpacity>

        <Text style={styles.note}>
          Later this will include profiles, ratings, availability, and direct booking in PGK.
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
