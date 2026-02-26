import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../models/booking_model.dart';
import '../../models/package_model.dart';
import '../../models/hotel_model.dart';
import '../../models/activity_model.dart';
import '../../utils/app_theme.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = legacy_provider.Provider.of<AuthProvider>(context);
    final trip = legacy_provider.Provider.of<TripProvider>(context);
    final bookingsAsync = ref.watch(userBookingsProvider(auth.user?.id));

    return bookingsAsync.when(
      data: (bookings) {
        final booking = bookings.firstWhere(
          (b) => b.id == widget.bookingId,
          orElse: () => throw Exception('Booking not found'),
        );
        final vendorAsync = ref.watch(vendorProvider(booking.vendorId));
        final vendor = vendorAsync.valueOrNull;
        return _buildUI(context, booking, trip, vendor);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildUI(BuildContext context, BookingModel booking, TripProvider trip,
      UserModel? vendor) {
    final isCompleted = booking.status == 'completed';
    final pkg = trip.packages.firstWhere(
      (p) => p.id == booking.packageId,
      orElse: () => PackageModel(
          id: '',
          name: '',
          city: '',
          country: '',
          image: '',
          basePrice: 0,
          minDays: 0,
          maxDays: 0,
          rating: 0,
          reviews: 0,
          category: '',
          difficulty: '',
          description: ''),
    );

    // Schedule reminders
    NotificationService().scheduleTripReminders(
      booking: booking,
      pkg: pkg,
      hotels: trip.hotels,
      destinations: trip.destinations,
    );

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [AppTheme.success, const Color(0xFF064E3B)]
                        : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
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
                        size: 48,
                        color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      isCompleted ? 'Trip Completed!' : 'Booking Confirmed!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Ref: ${booking.id.toUpperCase().substring(0, 8)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TripProgressBar(booking: booking),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              Container(
                color: AppTheme.bg,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: 'Itinerary'),
                          Tab(text: 'Summary'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              64,
            ),
          ),
          if (vendor != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Organizer',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: const Icon(Icons.business_rounded,
                                color: AppTheme.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        vendor.businessName ?? vendor.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded,
                                        color: Colors.blue, size: 16),
                                  ],
                                ),
                                if (vendor.businessPhone != null)
                                  Text(
                                    'Mobile: ${vendor.businessPhone}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13),
                                  ),
                                if (vendor.businessAddress != null)
                                  Text(
                                    vendor.businessAddress!,
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call_outlined,
                                color: AppTheme.primary),
                            onPressed: () {}, // Could launch url_launcher here
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _DetailedItineraryView(booking: booking, trip: trip, pkg: pkg),
            _BookingSummaryView(booking: booking, trip: trip, pkg: pkg),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  _SliverAppBarDelegate(this.child, this.height);
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(BuildContext context, double shrink, bool overlaps) => child;
  @override
  bool shouldRebuild(old) => true;
}

class _DetailedItineraryView extends StatelessWidget {
  final BookingModel booking;
  final TripProvider trip;
  final PackageModel pkg;
  const _DetailedItineraryView(
      {required this.booking, required this.trip, required this.pkg});

  @override
  Widget build(BuildContext context) {
    if (booking.dayPlan.isEmpty) {
      return const _EmptyState(text: 'No plan details available');
    }

    final days = booking.dayPlan.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final dayNum = days[index];
        final plan = booking.dayPlan[dayNum]!;
        return _DayExpansionTile(
            dayNum: dayNum, plan: plan, trip: trip, pkg: pkg, booking: booking);
      },
    );
  }
}

class _DayExpansionTile extends StatelessWidget {
  final int dayNum;
  final DayPlan plan;
  final TripProvider trip;
  final PackageModel pkg;
  final BookingModel booking;
  const _DayExpansionTile({
    required this.dayNum,
    required this.plan,
    required this.trip,
    required this.pkg,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final date = booking.bookedAt.add(Duration(days: dayNum - 1));
    final hotel = plan.hotelId != null ? trip.getHotel(plan.hotelId!) : null;
    final dest =
        plan.destinationId != null ? trip.getDest(plan.destinationId!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: dayNum == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Day',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600)),
                Text('$dayNum',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          title: Text(
            dayNum == 1
                ? 'Arrival & Check-in'
                : dest?.name ?? 'Exploring the City',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              if (plan.isCompleted)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: AppTheme.success.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 10, color: AppTheme.success),
                      SizedBox(width: 4),
                      Text('COMPLETED',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.success)),
                    ],
                  ),
                ),
              if (hotel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.hotel_rounded,
                          size: 12, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(hotel.name,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          trailing: Checkbox(
            value: plan.isCompleted,
            onChanged: (v) {
              if (v != null) {
                legacy_provider.Provider.of<TripProvider>(context,
                        listen: false)
                    .updateDayCompletion(booking.id, dayNum, v);
              }
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: AppTheme.success,
          ),
          children: [
            const Divider(color: AppTheme.border),
            _TimelineStep(
              time: plan.arrivalTime ?? '09:00 AM',
              icon: Icons.flight_takeoff_rounded,
              category: 'TRANSPORT',
              description: dayNum == 1
                  ? 'Arrive at destination & transfer to hotel'
                  : 'Commence morning travel',
              isCompleted: plan.isCompleted,
            ),
            if (pkg.breakfastMenu.isNotEmpty)
              _TimelineStep(
                time: '08:30 AM',
                icon: Icons.restaurant_rounded,
                category: 'MEAL',
                description: 'Breakfast: ${pkg.breakfastMenu}',
                isCompleted: plan.isCompleted,
                trailing: _MealCheck(
                  value: plan.breakfast,
                  onChanged: (v) => legacy_provider.Provider.of<TripProvider>(
                          context,
                          listen: false)
                      .updateDayMeals(booking.id, dayNum, breakfast: v),
                ),
              ),
            if (dest != null)
              _TimelineStep(
                time: '11:00 AM',
                icon: Icons.explore_rounded,
                category: 'EXPLORE',
                description: 'Visit ${dest.name}. ${dest.timeToVisit}',
                isCompleted: plan.isCompleted,
              ),
            if (pkg.lunchMenu.isNotEmpty)
              _TimelineStep(
                time: '01:30 PM',
                icon: Icons.restaurant_rounded,
                category: 'MEAL',
                description: 'Lunch: ${pkg.lunchMenu}',
                isCompleted: plan.isCompleted,
                trailing: _MealCheck(
                  value: plan.lunch,
                  onChanged: (v) => legacy_provider.Provider.of<TripProvider>(
                          context,
                          listen: false)
                      .updateDayMeals(booking.id, dayNum, lunch: v),
                ),
              ),
            if (hotel != null)
              _TimelineStep(
                time: plan.reachingTime ?? '04:00 PM',
                icon: Icons.hotel_rounded,
                category: 'HOTEL',
                description: 'Check-in or Return to ${hotel.name}',
                isCompleted: plan.isCompleted,
              ),
            _TimelineStep(
              time: '06:00 PM',
              icon: Icons.theater_comedy_rounded,
              category: 'LEISURE',
              description: 'Evening leisure and free exploration',
              isCompleted: plan.isCompleted,
            ),
            if (pkg.dinnerMenu.isNotEmpty)
              _TimelineStep(
                time: '08:30 PM',
                icon: Icons.restaurant_rounded,
                category: 'MEAL',
                description: 'Dinner: ${pkg.dinnerMenu}',
                isCompleted: plan.isCompleted,
                isLast: true,
                trailing: _MealCheck(
                  value: plan.dinner,
                  onChanged: (v) => legacy_provider.Provider.of<TripProvider>(
                          context,
                          listen: false)
                      .updateDayMeals(booking.id, dayNum, dinner: v),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String time;
  final IconData icon;
  final String category;
  final String description;
  final bool isCompleted;
  final bool isLast;
  final Widget? trailing;

  const _TimelineStep({
    required this.time,
    required this.icon,
    required this.category,
    required this.description,
    this.isCompleted = false,
    this.isLast = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  time.split(' ')[0],
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondary),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.bg2,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.primary),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: AppTheme.border,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 2),
                        Icon(icon, size: 10, color: AppTheme.primary2),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                              color: AppTheme.primary2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            trailing ??
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    size: 20,
                    color: isCompleted ? AppTheme.success : AppTheme.textMuted,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TripProgressBar extends StatelessWidget {
  final BookingModel booking;
  const _TripProgressBar({required this.booking});

  @override
  Widget build(BuildContext context) {
    final completed = booking.dayPlan.values.where((d) => d.isCompleted).length;
    final progress = completed / booking.days;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(progress * 100).toInt()}% Completed',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Text('$completed/${booking.days} Days',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MealCheck({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: value ? AppTheme.primary : AppTheme.border, width: 1.5),
        ),
        child: Icon(
          value ? Icons.check_rounded : Icons.add_rounded,
          size: 14,
          color: value ? AppTheme.primary : AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _BookingSummaryView extends StatelessWidget {
  final BookingModel booking;
  final TripProvider trip;
  final PackageModel pkg;
  const _BookingSummaryView({
    required this.booking,
    required this.trip,
    required this.pkg,
  });

  @override
  Widget build(BuildContext context) {
    // Get the first hotel from the plan
    HotelModel? hotel;
    for (var plan in booking.dayPlan.values) {
      if (plan.hotelId != null) {
        hotel = trip.hotels.where((h) => h.id == plan.hotelId).firstOrNull();
        if (hotel != null) break;
      }
    }

    final activities = booking.activityIds
        .map((id) => trip.activities.where((a) => a.id == id).firstOrNull())
        .whereType<ActivityModel>()
        .toList();

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _SummaryCard(
                        title: 'Package Details',
                        icon: Icons.inventory_2_rounded,
                        children: [
                          _DetailRow(
                              label: 'Package', value: booking.packageName),
                          _DetailRow(
                              label: 'Destination',
                              value: '${booking.packageCity}, ${pkg.country}'),
                          _DetailRow(
                              label: 'Duration', value: '${booking.days} days'),
                          _DetailRow(label: 'Category', value: pkg.category),
                          _DetailRow(
                              label: 'Booked On',
                              value: DateFormat('MMM d, yyyy')
                                  .format(booking.bookedAt)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SummaryCard(
                        title: 'Activities',
                        icon: Icons.track_changes_rounded,
                        children: [
                          if (activities.isEmpty)
                            const Text('No extra activities selected',
                                style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic))
                          else
                            ...activities.map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          size: 14, color: AppTheme.primary),
                                      const SizedBox(width: 10),
                                      Text(a.name,
                                          style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _SummaryCard(
                        title: 'Hotel',
                        icon: Icons.hotel_rounded,
                        children: [
                          _DetailRow(
                              label: 'Hotel',
                              value: hotel?.name ?? 'Not Selected'),
                          _DetailRow(
                              label: 'Stars',
                              value: hotel != null ? '⭐' * hotel.stars : 'N/A'),
                          _DetailRow(label: 'Check-in', value: 'Day 1'),
                          _DetailRow(
                              label: 'Check-out', value: 'Day ${booking.days}'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SummaryCard(
                        title: 'Payment Summary',
                        icon: Icons.payments_rounded,
                        children: [
                          _DetailRow(
                              label: 'Package Base',
                              value: '₹${pkg.basePrice.toStringAsFixed(0)}'),
                          _DetailRow(
                              label: 'Hotel (${booking.days} nights)',
                              value: '₹0'),
                          _DetailRow(
                              label: 'Activities',
                              value:
                                  '₹${(booking.totalPrice - pkg.basePrice).toStringAsFixed(0)}'),
                          const Divider(height: 32, color: AppTheme.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Paid',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              Text('₹${booking.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.accent)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _SummaryCard(
              title: 'Package Details',
              icon: Icons.inventory_2_rounded,
              children: [
                _DetailRow(label: 'Package', value: booking.packageName),
                _DetailRow(
                    label: 'Destination',
                    value: '${booking.packageCity}, ${pkg.country}'),
                _DetailRow(label: 'Duration', value: '${booking.days} days'),
                _DetailRow(label: 'Category', value: pkg.category),
                _DetailRow(
                    label: 'Booked On',
                    value: DateFormat('MMM d, yyyy').format(booking.bookedAt)),
              ],
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              title: 'Hotel',
              icon: Icons.hotel_rounded,
              children: [
                _DetailRow(
                    label: 'Hotel', value: hotel?.name ?? 'Not Selected'),
                _DetailRow(
                    label: 'Stars',
                    value: hotel != null ? '⭐' * hotel.stars : 'N/A'),
                _DetailRow(label: 'Check-in', value: 'Day 1'),
                _DetailRow(label: 'Check-out', value: 'Day ${booking.days}'),
              ],
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              title: 'Activities',
              icon: Icons.track_changes_rounded,
              children: [
                if (activities.isEmpty)
                  const Text('No extra activities selected',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic))
                else
                  ...activities.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            Text(a.name, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )),
              ],
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              title: 'Payment Summary',
              icon: Icons.payments_rounded,
              children: [
                _DetailRow(
                    label: 'Package Base',
                    value: '₹${pkg.basePrice.toStringAsFixed(0)}'),
                _DetailRow(
                    label: 'Hotel (${booking.days} nights)', value: '₹0'),
                _DetailRow(
                    label: 'Activities',
                    value:
                        '₹${(booking.totalPrice - pkg.basePrice).toStringAsFixed(0)}'),
                const Divider(height: 32, color: AppTheme.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('₹${booking.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent)),
                  ],
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
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

extension ListX<T> on Iterable<T> {
  T? firstOrNull() {
    return isNotEmpty ? first : null;
  }
}
