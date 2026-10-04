import QuoteRequestScreen from '../../../components/marketplace/QuoteRequestScreen';

export default function PeopleHireScreen() {
  return (
    <QuoteRequestScreen
      categorySlug="general-labour"
      title="People & General Labour"
      subtitle="Post a job or short-term work request and receive quotes from verified Wantok Service providers."
      examples={[
        'General labour and site helpers',
        'Loading, moving and event setup crews',
        'Gardening, cleaning and property help',
        'Short-term project or community work',
        'Other lawful casual work by agreement',
      ]}
      requestLabel="Post labour request"
    />
  );
}
