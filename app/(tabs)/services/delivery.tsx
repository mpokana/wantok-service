import ServiceModulePreview from '../../../components/ServiceModulePreview';

export default function DeliveryScreen() {
  return (
    <ServiceModulePreview
      title="Delivery & Errands"
      subtitle="Send parcels and documents, arrange collections, or ask a trusted provider to buy or collect items for you."
      items={[
        'Courier pickup and drop-off requests',
        'Errand / Pabili-style buy-and-deliver tasks',
        'Scheduled or on-demand fulfilment',
        'Live status, proof of collection/delivery and provider tracking',
        'Later: item value limits, insurance rules, payments and multi-stop delivery',
      ]}
      statusText="Delivery will share customer identity, providers, payments, reviews and notifications with the rest of Wantok Service, while keeping delivery-specific pickup/drop-off tracking in its own module."
    />
  );
}
