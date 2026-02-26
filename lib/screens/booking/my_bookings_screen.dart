import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/booking_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/trip_image.dart';

import '../../providers/booking_provider.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = legacy_provider.Provider.of<AuthProvider>(context);
    final trip = legacy_provider.Provider.of<TripProvider>(context);
    final bookingsAsync = ref.watch(userBookingsProvider(auth.user?.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: !auth.isLoggedIn
          ? _buildLoginPrompt(context)
          : bookingsAsync.when(
              data: (bookings) => bookings.isEmpty
                  ? _buildEmptyState()
                  : _buildBookingList(context, ref, bookings, trip),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 54, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('Sign in to see your bookings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.luggage_rounded, size: 54, color: AppTheme.textMuted),
          SizedBox(height: 12),
          Text("You haven't booked any trips yet",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, WidgetRef ref,
      List<BookingModel> bookings, TripProvider trip) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = bookings[i];
        return GestureDetector(
          onTap: () => context.push('/booking/${b.id}'),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                TripImage(
                  imageUrl: b.packageImage,
                  width: 100,
                  height: 100,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                b.packageName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _StatusChip(status: b.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('📍 ${b.packageCity}',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                        Text(
                          '${b.days} days package · ${DateFormat('MMM d, yyyy').format(b.bookedAt)}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        _TripSummary(booking: b, trip: trip),
                        const SizedBox(height: 8),
                        Text('₹${b.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                      ],
                    ),
                  ),
                ),
                _buildActionCol(ref, b),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCol(WidgetRef ref, BookingModel b) {
    return Column(
      children: [
        if (b.status == 'confirmed')
          IconButton(
            onPressed: () => ref
                .read(bookingActionProvider.notifier)
                .updateStatus(b.id, 'completed'),
            icon: const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.textMuted, size: 24),
            tooltip: 'Mark as Completed',
          )
        else if (b.status == 'completed')
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 28),
          ),
        const Icon(Icons.chevron_right_rounded,
            color: AppTheme.textMuted, size: 20),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isComp = status == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isComp ? AppTheme.success : AppTheme.primary).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isComp ? AppTheme.success : AppTheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TripSummary extends StatelessWidget {
  final BookingModel booking;
  final TripProvider trip;

  const _TripSummary({
    required this.booking,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    // Collect unique names
    final hotelNames = <String>{};
    final spotNames = <String>{};

    for (var plan in booking.dayPlan.values) {
      if (plan.hotelId != null) {
        final h = trip.getHotel(plan.hotelId!);
        if (h != null) hotelNames.add(h.name);
      }
      if (plan.destinationId != null) {
        final d = trip.getDest(plan.destinationId!);
        if (d != null) spotNames.add(d.name);
      }
    }

    if (hotelNames.isEmpty && spotNames.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hotelNames.isNotEmpty)
          _SummaryRow(
            icon: Icons.hotel_rounded,
            text: hotelNames.join(', '),
          ),
        if (spotNames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _SummaryRow(
              icon: Icons.explore_rounded,
              text: spotNames.join(', '),
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SummaryRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 10, color: AppTheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
}
