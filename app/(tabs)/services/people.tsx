import ServiceModulePreview from '../../../components/ServiceModulePreview';

export default function PeopleHireScreen() {
  return (
    <ServiceModulePreview
      title="People & General Labour"
      subtitle="Find verified workers and helpers for short jobs, scheduled work, projects and local tasks."
      items={[
        'Post an open job request and receive quotes from qualified providers',
        'Hire by job, hour, day or negotiated quote',
        'Schedule start/end times and work locations',
        'Provider profiles, verification, ratings and completed-job history',
        'Later: chat, payments, dispute handling and repeat hiring',
      ]}
      statusText="The shared booking, quote, provider-service and review tables are being built for this workflow. The next UI phase will replace this preview with live search, requests and provider matching."
    />
  );
}
