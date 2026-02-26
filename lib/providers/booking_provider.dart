import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter/material.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

// User Bookings Provider
final userBookingsProvider =
    StreamProvider.family<List<BookingModel>, String?>((ref, userId) {
  if (userId == null) return Stream.value([]);
  final db = ref.watch(firestoreServiceProvider);
  return db.userBookingsStream(userId);
});

// Booking Operations Notifier
class BookingNotifier extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateDayStatus(
      String bookingId, int day, bool completed) async {
    state = const AsyncLoading();
    try {
      final db = ref.read(firestoreServiceProvider);
      await db.updateDayCompletion(bookingId, day, completed);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateMeals(String bookingId, int day,
      {bool? breakfast, bool? lunch, bool? dinner}) async {
    state = const AsyncLoading();
    try {
      final db = ref.read(firestoreServiceProvider);
      await db.updateDayMeals(bookingId, day,
          breakfast: breakfast, lunch: lunch, dinner: dinner);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateStatus(String bookingId, String status) async {
    state = const AsyncLoading();
    try {
      final db = ref.read(firestoreServiceProvider);
      await db.updateBookingStatus(bookingId, status);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final bookingActionProvider =
    AutoDisposeNotifierProvider<BookingNotifier, AsyncValue<void>>(
        BookingNotifier.new);
