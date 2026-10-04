export type LatLng = {
  latitude: number;
  longitude: number;
};

export type TaxiMapRegion = LatLng & {
  latitudeDelta: number;
  longitudeDelta: number;
};

export type TaxiMapDriver = {
  driver_id: string;
  name?: string | null;
  phone?: string | null;
  vehicle_rego?: string | null;
  vehicle_model?: string | null;
  vehicle_colour?: string | null;
  vehicle_image_url?: string | null;
  lat: number;
  lng: number;
};

export type TaxiMapProps = {
  region: TaxiMapRegion;
  pickup: LatLng | null;
  destination: LatLng | null;
  drivers: TaxiMapDriver[];
  onRegionChangeComplete: (region: TaxiMapRegion) => void;
  onPress: (coordinate: LatLng) => void;
};
