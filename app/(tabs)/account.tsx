import { View, Text, StyleSheet } from 'react-native';

export default function AccountScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Account</Text>
      <Text style={styles.text}>
        Basic account and profile view placeholder.
        Later we’ll show your details, saved places, and settings here.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    padding: 20,
    paddingTop: 50,
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#FFD700',
    marginBottom: 8,
  },
  text: {
    fontSize: 13,
    color: '#E5E7EB',
  },
});
