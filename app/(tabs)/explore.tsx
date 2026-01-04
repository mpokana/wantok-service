import { View, Text, StyleSheet, ScrollView } from 'react-native';

export default function ExploreScreen() {
  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>About Wantok Service</Text>
        <Text style={styles.subtitle}>Your Everyday Helper in PNG</Text>

        <Text style={styles.text}>
          Wantok Service is a multi-service platform designed for Papua New Guinea.
          One app to help you move, eat, and get things done with local providers.
        </Text>

        <Text style={styles.sectionTitle}>Core Services</Text>
        <Text style={styles.listItem}>• Taxi / ride bookings with local drivers.</Text>
        <Text style={styles.listItem}>• Food delivery from kai bars and restaurants.</Text>
        <Text style={styles.listItem}>• Errands & deliveries for parcels and market goods.</Text>

        <Text style={styles.sectionTitle}>Local Focus</Text>
        <Text style={styles.listItem}>• Prices shown in PNG Kina (PGK).</Text>
        <Text style={styles.listItem}>• Runs on PNG time zone.</Text>
        <Text style={styles.listItem}>• Designed to handle low / unstable connectivity.</Text>

        <Text style={styles.sectionTitle}>This build</Text>
        <Text style={styles.text}>
          You are running an early MVP using Expo Go (for testing) and Supabase as the backend.
          Next steps include live driver tracking with OpenStreetMap, secure driver / vendor
          onboarding, and integrations for cash, mobile money, and card payments.
        </Text>

        <Text style={styles.footer}>Wantok Service · Early Build Preview</Text>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
  content: {
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: '700',
    color: '#FFD700',
    marginBottom: 4,
  },
  subtitle: {
    fontSize: 16,
    color: '#FFFFFF',
    marginBottom: 16,
  },
  text: {
    fontSize: 14,
    color: '#DDDDDD',
    marginBottom: 10,
    lineHeight: 20,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFD700',
    marginTop: 14,
    marginBottom: 6,
  },
  listItem: {
    fontSize: 14,
    color: '#DDDDDD',
    marginBottom: 4,
    paddingLeft: 4,
  },
  footer: {
    fontSize: 12,
    color: '#777777',
    marginTop: 24,
  },
});
