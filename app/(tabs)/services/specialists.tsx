import QuoteRequestScreen from '../../../components/marketplace/QuoteRequestScreen';

export default function SpecialistsScreen() {
  return (
    <QuoteRequestScreen
      categorySlug="specialist-services"
      title="Specialist Services"
      subtitle="Describe the work you need and receive quotes from verified specialists and trades providers."
      examples={[
        'Electrical, solar, plumbing and building work',
        'ICT, networking and technical support',
        'Drivers, logistics coordinators and guides',
        'Translators, trainers and consultants',
        'Photography, media and event crew',
      ]}
      requestLabel="Post specialist request"
    />
  );
}
