import React from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

type Props = {
  title: string;
  subtitle: string;
  items: string[];
  statusText: string;
};

export default function ServiceModulePreview({
  title,
  subtitle,
  items,
  statusText,
}: Props) {
  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>{title}</Text>
        <Text style={styles.subtitle}>{subtitle}</Text>

        <Text style={styles.section}>Planned capabilities</Text>
        {items.map((item) => (
          <Text key={item} style={styles.item}>
            • {item}
          </Text>
        ))}

        <View style={styles.statusBox}>
          <Text style={styles.statusTitle}>Marketplace core ready</Text>
          <Text style={styles.statusText}>{statusText}</Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#000' },
  content: { padding: 20, paddingBottom: 40 },
  title: { fontSize: 22, fontWeight: '700', color: '#FFD700', marginBottom: 4 },
  subtitle: { color: '#F3F4F6', fontSize: 13, lineHeight: 19, marginBottom: 18 },
  section: { color: '#FFD700', fontWeight: '600', marginBottom: 8 },
  item: { color: '#D1D5DB', fontSize: 13, marginBottom: 6, lineHeight: 18 },
  statusBox: {
    marginTop: 18,
    borderWidth: 1,
    borderColor: '#374151',
    backgroundColor: '#0B0B0B',
    borderRadius: 12,
    padding: 14,
  },
  statusTitle: { color: '#FACC15', fontWeight: '700', marginBottom: 4 },
  statusText: { color: '#9CA3AF', fontSize: 12, lineHeight: 18 },
});
