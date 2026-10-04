import ServiceModulePreview from '../../../components/ServiceModulePreview';

export default function FoodShoppingScreen() {
  return (
    <ServiceModulePreview
      title="Food, Groceries & Shops"
      subtitle="Discover approved merchants, build an order and arrange pickup or delivery from the same Wantok Service account."
      items={[
        'Restaurant and food-vendor storefronts',
        'Groceries and participating local shops',
        'Menus/catalogues, item options and stock availability',
        'Pickup or delivery fulfilment',
        'Later: merchant settlement, promotions, rewards and group orders',
      ]}
      statusText="Commerce will use the same provider and customer platform but will get specialised merchant, catalogue, cart, order-item and fulfilment tables instead of being forced into generic service bookings."
    />
  );
}
