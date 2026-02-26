import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:go_router/go_router.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/booking_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/trip_image.dart';

class BookingScreen extends ConsumerWidget {
  final String bookingId;
  const BookingScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = legacy_provider.Provider.of<AuthProvider>(context);
    final trip = legacy_provider.Provider.of<TripProvider>(context);
    final bookingsAsync = ref.watch(userBookingsProvider(auth.user?.id));

    return bookingsAsync.when(
      data: (bookings) {
        final booking = bookings.firstWhere(
          (b) => b.id == bookingId,
          orElse: () => throw Exception('Booking not found'),
        );
        return _buildUI(context, ref, booking, trip);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildUI(BuildContext context, WidgetRef ref, BookingModel booking,
      TripProvider trip) {
    final isCompleted = booking.status == 'completed';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [AppTheme.success, const Color(0xFF064E3B)]
                        : [const Color(0xFF10B981), const Color(0xFF015249)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        isCompleted
                            ? Icons.verified_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 64,
                        color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      isCompleted ? 'Trip Completed!' : 'Booking Confirmed!',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ID: ${booking.id}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          TripImage(
                            imageUrl: booking.packageImage,
                            width: 100,
                            height: 100,
                            borderRadius: 50,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            booking.packageName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            booking.packageCity,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const Divider(height: 32, color: AppTheme.border),
                          _DetailRow(
                            icon: Icons.notifications_active_rounded,
                            label: 'Notifications',
                            value: booking.notificationsEnabled
                                ? 'ENABLED'
                                : 'DISABLED',
                            valueColor: booking.notificationsEnabled
                                ? AppTheme.success
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.payment_rounded,
                            label: 'Amount Paid',
                            value: '₹${booking.totalPrice.toStringAsFixed(0)}',
                            valueColor: AppTheme.accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your Detailed Itinerary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    if (booking.dayPlan.isEmpty)
                      const _EmptyState(text: 'No plan details available')
                    else
                      ...booking.dayPlan.entries.map((e) {
                        final d = e.key;
                        final plan = e.value;
                        return _ItineraryItem(
                          bookingId: booking.id,
                          day: d,
                          plan: plan,
                          isLast: d == booking.days,
                          trip: trip,
                        );
                      }),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Back to Dashboard'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.push('/my-bookings'),
                      child: const Text('View All Transactions'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      );
}

class _ItineraryItem extends ConsumerWidget {
  final String bookingId;
  final int day;
  final DayPlan plan;
  final bool isLast;
  final TripProvider trip;

  const _ItineraryItem({
    required this.bookingId,
    required this.day,
    required this.plan,
    required this.isLast,
    required this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dest =
        plan.destinationId != null ? trip.getDest(plan.destinationId!) : null;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              GestureDetector(
                onTap: () => ref
                    .read(bookingActionProvider.notifier)
                    .updateDayStatus(bookingId, day, !plan.isCompleted),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: plan.isCompleted
                        ? AppTheme.success
                        : AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: plan.isCompleted
                            ? AppTheme.success
                            : AppTheme.primary,
                        width: 2),
                  ),
                  child: Center(
                    child: plan.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text(
                            '$day',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppTheme.primary,
                            ),
                          ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: plan.isCompleted
                        ? AppTheme.success.withOpacity(0.3)
                        : AppTheme.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: plan.isCompleted
                        ? AppTheme.success.withOpacity(0.5)
                        : AppTheme.border,
                    width: plan.isCompleted ? 2 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dest?.name ??
                              (plan.destinationId ?? 'Exploring City'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            decoration: plan.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: plan.isCompleted
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (plan.arrivalTime != null)
                        _Tag(text: plan.arrivalTime!, icon: Icons.login),
                    ],
                  ),
                  if (dest != null && dest.timeToVisit.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '⏱ Recommended: ${dest.timeToVisit}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (plan.hotelId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.hotel_rounded,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          trip.getHotel(plan.hotelId!)?.name ?? plan.hotelId!,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MealChip(
                        label: 'Breakfast (8 AM)',
                        active: plan.breakfast,
                        onTap: () => ref
                            .read(bookingActionProvider.notifier)
                            .updateMeals(bookingId, day,
                                breakfast: !plan.breakfast),
                      ),
                      const SizedBox(width: 6),
                      _MealChip(
                        label: 'Lunch (1 PM)',
                        active: plan.lunch,
                        onTap: () => ref
                            .read(bookingActionProvider.notifier)
                            .updateMeals(bookingId, day, lunch: !plan.lunch),
                      ),
                      const SizedBox(width: 6),
                      _MealChip(
                        label: 'Dinner (8 PM)',
                        active: plan.dinner,
                        onTap: () => ref
                            .read(bookingActionProvider.notifier)
                            .updateMeals(bookingId, day, dinner: !plan.dinner),
                      ),
                    ],
                  ),
                  if (plan.reachingTime != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Estimated Completion: ',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted)),
                        Text(
                          plan.reachingTime!,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MealChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withOpacity(0.2) : AppTheme.bg2,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: active ? AppTheme.primary : AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  active ? Icons.restaurant_rounded : Icons.restaurant_outlined,
                  size: 10,
                  color: active ? AppTheme.primary : AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                label.split(' ')[0],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Tag({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.bg2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: AppTheme.textMuted)),
        ),
      );
}
