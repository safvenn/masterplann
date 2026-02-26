import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/package_model.dart';
import '../models/hotel_model.dart';
import '../models/destination_model.dart';
import '../models/booking_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── PACKAGES ─────────────────────────────────────────────────────
  Stream<List<PackageModel>> packagesStream() => _db
      .collection('packages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PackageModel.fromFirestore).toList());

  Future<PackageModel?> getPackage(String id) async {
    final doc = await _db.collection('packages').doc(id).get();
    if (!doc.exists) return null;
    return PackageModel.fromFirestore(doc);
  }

  Future<String> addPackage(PackageModel pkg) async {
    final ref = await _db.collection('packages').add(pkg.toFirestore());
    return ref.id;
  }

  Future<void> updatePackage(String id, Map<String, dynamic> data) =>
      _db.collection('packages').doc(id).update(data);

  Future<void> deletePackage(String id) =>
      _db.collection('packages').doc(id).delete();

  // ── HOTELS ────────────────────────────────────────────────────────
  Stream<List<HotelModel>> hotelsStream() => _db
      .collection('hotels')
      .snapshots()
      .map((s) => s.docs.map(HotelModel.fromFirestore).toList());

  Future<List<HotelModel>> getHotelsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) => _db.collection('hotels').doc(id).get());
    final docs = await Future.wait(futures);
    return docs.where((d) => d.exists).map(HotelModel.fromFirestore).toList();
  }

  Future<String> addHotel(HotelModel hotel) async {
    final ref = await _db.collection('hotels').add(hotel.toFirestore());
    return ref.id;
  }

  Future<void> updateHotel(String id, Map<String, dynamic> data) =>
      _db.collection('hotels').doc(id).update(data);

  Future<void> deleteHotel(String id) =>
      _db.collection('hotels').doc(id).delete();

  // ── DESTINATIONS ──────────────────────────────────────────────────
  Stream<List<DestinationModel>> destinationsStream() => _db
      .collection('destinations')
      .snapshots()
      .map((s) => s.docs.map(DestinationModel.fromFirestore).toList());

  Future<List<DestinationModel>> getDestinationsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map(
      (id) => _db.collection('destinations').doc(id).get(),
    );
    final docs = await Future.wait(futures);
    return docs
        .where((d) => d.exists)
        .map(DestinationModel.fromFirestore)
        .toList();
  }

  Future<String> addDestination(DestinationModel dest) async {
    final ref = await _db.collection('destinations').add(dest.toFirestore());
    return ref.id;
  }

  Future<void> updateDestination(String id, Map<String, dynamic> data) =>
      _db.collection('destinations').doc(id).update(data);

  Future<void> deleteDestination(String id) =>
      _db.collection('destinations').doc(id).delete();

  // ── BOOKINGS ──────────────────────────────────────────────────────
  Stream<List<BookingModel>> userBookingsStream(String userId) => _db
      .collection('bookings')
      .where('userId', isEqualTo: userId)
      .orderBy('bookedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(BookingModel.fromFirestore).toList());

  Stream<List<BookingModel>> allBookingsStream() => _db
      .collection('bookings')
      .orderBy('bookedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(BookingModel.fromFirestore).toList());

  Future<String> createBooking(BookingModel booking) async {
    final ref = await _db.collection('bookings').add(booking.toFirestore());
    return ref.id;
  }

  Future<void> updateBookingStatus(String id, String status) =>
      _db.collection('bookings').doc(id).update({'status': status});

  Future<void> updateDayCompletion(String bookingId, int day, bool completed) =>
      _db.collection('bookings').doc(bookingId).update({
        'dayPlan.$day.isCompleted': completed,
      });

  Future<void> updateDayMeals(String bookingId, int day,
          {bool? breakfast, bool? lunch, bool? dinner}) =>
      _db.collection('bookings').doc(bookingId).update({
        if (breakfast != null) 'dayPlan.$day.breakfast': breakfast,
        if (lunch != null) 'dayPlan.$day.lunch': lunch,
        if (dinner != null) 'dayPlan.$day.dinner': dinner,
      });

  Future<void> deleteBooking(String id) =>
      _db.collection('bookings').doc(id).delete();
}
