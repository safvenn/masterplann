import 'package:flutter/material.dart';
import '../models/package_model.dart';
import '../models/hotel_model.dart';
import '../models/destination_model.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';

class TripProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  List<PackageModel> _packages = [];
  List<HotelModel> _hotels = [];
  List<DestinationModel> _destinations = [];
  List<BookingModel> _bookings = [];
  bool _loading = false;
  String? _error;

  Map<String, HotelModel> _hotelMap = {};
  Map<String, DestinationModel> _destMap = {};

  List<PackageModel> get packages => _packages;
  List<HotelModel> get hotels => _hotels;
  List<DestinationModel> get destinations => _destinations;
  List<BookingModel> get bookings => _bookings;
  bool get loading => _loading;
  String? get error => _error;

  // Optimized Getters
  HotelModel? getHotel(String id) => _hotelMap[id];
  DestinationModel? getDest(String id) => _destMap[id];

  void init(String? userId) {
    _db.packagesStream().listen((list) {
      _packages = list;
      notifyListeners();
    });
    _db.hotelsStream().listen((list) {
      _hotels = list;
      _hotelMap = {for (var h in list) h.id: h};
      notifyListeners();
    });
    _db.destinationsStream().listen((list) {
      _destinations = list;
      _destMap = {for (var d in list) d.id: d};
      notifyListeners();
    });
    if (userId != null) {
      _db.userBookingsStream(userId).listen((list) {
        _bookings = list;
        notifyListeners();
      });
    }
  }

  // Helpers
  List<HotelModel> hotelsForPackage(PackageModel pkg) =>
      _hotels.where((h) => pkg.hotelIds.contains(h.id)).toList();

  List<DestinationModel> destinationsForPackage(PackageModel pkg) =>
      _destinations.where((d) => pkg.destinationIds.contains(d.id)).toList();

  // Optimized Price calc
  double calcPrice(PackageModel pkg, int days, Map<int, DayPlan> dayPlan) {
    final base = pkg.basePrice + (days - pkg.minDays) * 150;
    double hotelCost = 0;
    for (int d = 1; d < days; d++) {
      final hId = dayPlan[d]?.hotelId;
      if (hId != null) {
        final hotel = _hotelMap[hId];
        if (hotel != null) hotelCost += hotel.pricePerNight;
      }
    }
    return base + hotelCost;
  }

  // Booking
  Future<String?> createBooking({
    required String userId,
    required PackageModel pkg,
    required int days,
    required Map<int, DayPlan> dayPlan,
    required List<String> activityIds,
    required double totalPrice,
    bool notificationsEnabled = true,
  }) async {
    try {
      final booking = BookingModel(
        id: '',
        userId: userId,
        packageId: pkg.id,
        packageName: pkg.name,
        packageCity: pkg.city,
        packageImage: pkg.image,
        days: days,
        dayPlan: dayPlan,
        activityIds: activityIds,
        totalPrice: totalPrice,
        status: 'confirmed',
        bookedAt: DateTime.now(),
        notificationsEnabled: notificationsEnabled,
      );
      final id = await _db.createBooking(booking);
      return id;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Admin CRUD
  Future<void> addPackage(PackageModel pkg) => _db.addPackage(pkg);
  Future<void> updatePackage(String id, Map<String, dynamic> data) =>
      _db.updatePackage(id, data);
  Future<void> deletePackage(String id) => _db.deletePackage(id);

  Future<void> addHotel(HotelModel h) => _db.addHotel(h);
  Future<void> updateHotel(String id, Map<String, dynamic> data) =>
      _db.updateHotel(id, data);
  Future<void> deleteHotel(String id) => _db.deleteHotel(id);

  Future<void> addDestination(DestinationModel d) => _db.addDestination(d);
  Future<void> updateDestination(String id, Map<String, dynamic> data) =>
      _db.updateDestination(id, data);
  Future<void> deleteDestination(String id) => _db.deleteDestination(id);

  Future<void> deleteBooking(String id) => _db.deleteBooking(id);

  Future<void> updateBookingStatus(String id, String status) async {
    try {
      await _db.updateBookingStatus(id, status);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
