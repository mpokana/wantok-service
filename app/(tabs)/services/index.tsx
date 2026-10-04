import { Href, useRouter } from 'expo-router';
import { ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

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

        <TouchableOpacity style={styles.card} onPress={() => go('/services/taxi')}>
          <Text style={styles.cardTitle}>Book Taxi / Ride</Text>
          <Text style={styles.cardText}>
            Live map, pickup & destination, request nearby trusted drivers.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/my-rides')}>
          <Text style={styles.cardTitle}>My Rides</Text>
          <Text style={styles.cardText}>
            View current and previous rides, status, distance and fare estimates.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/hire')}>
          <Text style={styles.cardTitle}>Hire Car & Boats</Text>
          <Text style={styles.cardText}>
            Long-term vehicles and private boats for business, NGOs, groups.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/boats')}>
          <Text style={styles.cardTitle}>Boat & Ship Rides</Text>
          <Text style={styles.cardText}>
            PMV dinghies, ferries and island routes (MVP info & booking flow).
          </Text>
        </TouchableOpacity>

        <Text style={styles.sectionLabel}>Places & Events</Text>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/venues')}>
          <Text style={styles.cardTitle}>Venue Booking</Text>
          <Text style={styles.cardText}>
            Halls, conference rooms, fields and other spaces.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/events')}>
          <Text style={styles.cardTitle}>Upcoming Events</Text>
          <Text style={styles.cardText}>
            Curated local events with links to transport and venue options.
          </Text>
        </TouchableOpacity>

        <Text style={styles.sectionLabel}>People</Text>

        <TouchableOpacity
          style={styles.card}
          onPress={() => go('/services/specialists')}
        >
          <Text style={styles.cardTitle}>Specialist Services</Text>
          <Text style={styles.cardText}>
            Connect with vetted professionals for technical and project work.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/people')}>
          <Text style={styles.cardTitle}>People & General Labour</Text>
          <Text style={styles.cardText}>
            Hire verified workers and helpers by job, hour, day or quote.
          </Text>
        </TouchableOpacity>

        <Text style={styles.sectionLabel}>Delivery & Shopping</Text>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/delivery')}>
          <Text style={styles.cardTitle}>Delivery & Errands</Text>
          <Text style={styles.cardText}>
            Send parcels, arrange collections, or request buy-and-deliver errands.
          </Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.card} onPress={() => go('/services/food')}>
          <Text style={styles.cardTitle}>Food, Groceries & Shops</Text>
          <Text style={styles.cardText}>
            Discover approved merchants for food, groceries and everyday goods.
          </Text>
        </TouchableOpacity>

        <Text style={styles.footer}>
          Later modules include buses, accommodation, flights, payments, rewards and other PNG services.
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
