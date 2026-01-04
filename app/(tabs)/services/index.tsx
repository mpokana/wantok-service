import { View, Text, TouchableOpacity, ScrollView, StyleSheet } from 'react-native';
import { useRouter, Href } from 'expo-router';

export default function ServicesHomeScreen() {
  const router = useRouter();

  // Correct typing for Expo Router
  const go = (route: Href) => {
    router.push(route);
  };

  return (
    <View style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.content}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.title}>Wantok Services</Text>
        <Text style={styles.subtitle}>
          Choose a service below. All bookings are handled inside this one app.
        </Text>

        <Text style={styles.sectionLabel}>Transport</Text>

        <TouchableOpacity
          style={styles.card}
          onPress={() => go('/(tabs)/services/taxi')}
        >
          <Text style={styles.cardTitle}>Book Taxi / Ride</Text>
          <Text style={styles.cardText}>
            Live map, pickup & destination, request nearby trusted drivers.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => go('/(tabs)/services/hire')}
        >
          <Text style={styles.cardTitle}>Hire Car & Boats</Text>
          <Text style={styles.cardText}>
            Long-term vehicles and private boats for business, NGOs, groups.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => go('/(tabs)/services/boats')}
        >
          <Text style={styles.cardTitle}>Boat & Ship Rides</Text>
          <Text style={styles.cardText}>
            PMV dinghies, ferries and island routes (MVP info & booking flow).
          </Text>
        </TouchableOpacity>

        <Text style={styles.sectionLabel}>Places & Events</Text>

        <TouchableOpacity
          style={styles.card}
          onPress={() => go('/(tabs)/services/venues')}
        >
          <Text style={styles.cardTitle}>Venue Booking</Text>
          <Text style={styles.cardText}>
            Halls, conference rooms, fields and other spaces.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.card}
          onPress={() => go('/(tabs)/services/events')}
        >
          <Text style={styles.cardTitle}>Upcoming Events</Text>
          <Text style={styles.cardText}>
            Curated local events with links to transport and venue options.
          </Text>
        </TouchableOpacity>

        <Text style={styles.sectionLabel}>People</Text>

        <TouchableOpacity
          style={styles.card}
          onPress={() => go('/(tabs)/services/specialists')}
        >
          <Text style={styles.cardTitle}>Specialist Services</Text>
          <Text style={styles.cardText}>
            Connect with vetted professionals for technical and project work.
          </Text>
        </TouchableOpacity>

        <Text style={styles.footer}>
          More categories (food, errands, delivery) will be added here later.
        </Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  content: {
    padding: 20,
    paddingBottom: 40,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFD700',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 13,
    color: '#FFFFFF',
    marginBottom: 18,
  },
  sectionLabel: {
    fontSize: 12,
    color: '#9CA3AF',
    marginTop: 12,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  card: {
    backgroundColor: '#0B0B0B',
    borderRadius: 12,
    padding: 14,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#1F2937',
  },
  cardTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#FFD700',
    marginBottom: 2,
  },
  cardText: {
    fontSize: 12,
    color: '#D1D5DB',
  },
  footer: {
    fontSize: 11,
    color: '#6B7280',
    marginTop: 18,
  },
});
