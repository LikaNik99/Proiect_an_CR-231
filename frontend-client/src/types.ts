export type LoginResponse = { token: string; role: string; adminRestaurantIds: number[] };

export type RestaurantDto = {
  id: number;
  name: string;
  address: string;
  openTime: string;
  closeTime: string;
  crossesMidnight: boolean;
  cuisine?: string;
  priceSign?: string;
  imageUrl?: string;
};

export type ReservationDto = {
  id: number;
  restaurantId: number;
  restaurantName: string;
  tableId: number;
  tableNo: number;
  startDt: string;
  endDt: string;
  persons: number;
  durationMin: number;
  status: string;
  customerName: string;
  customerEmail: string;
};

export type CreateReservationRequest = {
  restaurantId: number;
  startDt: string; // ISO cu offset
  persons: number;
  durationMin: number;
};
