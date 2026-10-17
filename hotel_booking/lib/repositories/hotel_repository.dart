import '../models/models.dart';
import '../services/api_service.dart';

class HotelRepository {
  final ApiService api;
  HotelRepository(this.api);
  Future<PageData<Room>> rooms(Json query, {bool available = true}) async =>
      PageData.fromJson(
        await api.request(
          'GET',
          available ? '/rooms/available' : '/rooms',
          query: query,
        ) as Json,
        Room.fromJson,
      );
  Future<PageData<Booking>> bookings(bool staff, Json query) async =>
      PageData.fromJson(
        await api.request(
          'GET',
          staff ? '/staff/bookings' : '/bookings/my',
          query: query,
        ) as Json,
        Booking.fromJson,
      );
  Future<Booking> book(BookingRequest data) async => Booking.fromJson(
    await api.request('POST', '/bookings', body: data.toJson()) as Json,
  );
}
