import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/trip_image.dart';
import '../../models/package_model.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class PackageDetailScreen extends StatefulWidget {
  final String packageId;
  const PackageDetailScreen({super.key, required this.packageId});
  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  PackageModel? _pkg;
  UserModel? _vendor;
  int _days = 3;
  Map<int, DayPlan> _dayPlan = {};
  List<String> _selectedActivities = [];
  bool _loading = false;
  bool _notificationsEnabled = true;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPackage());
  }

  void _loadPackage() {
    final trip = context.read<TripProvider>();
    final pkg = trip.packages.firstWhere(
      (p) => p.id == widget.packageId,
      orElse: () => PackageModel(
        id: '',
        name: 'Not Found',
        city: '',
        country: '',
        image: '',
        basePrice: 0,
        minDays: 1,
        maxDays: 1,
        rating: 0,
        reviews: 0,
        category: '',
        difficulty: '',
        description: '',
      ),
    );
    setState(() {
      _pkg = pkg;
      _days = pkg.minDays;
      _buildDefaultPlan(trip, pkg);
    });

    if (pkg.vendorId.isNotEmpty) {
      AuthService().getUserModel(pkg.vendorId).then((v) {
        if (mounted) setState(() => _vendor = v);
      });
    }
  }

  void _buildDefaultPlan(TripProvider trip, PackageModel pkg) {
    final hotels = trip.hotelsForPackage(pkg);
    final dests = trip.destinationsForPackage(pkg);
    final plan = <int, DayPlan>{};
    for (int d = 1; d <= _days; d++) {
      final isArrival = d == 1;
      final isDeparture = d == _days;
      final destIdx = (!isArrival && !isDeparture && dests.isNotEmpty)
          ? (d - 2) % dests.length
          : -1;
      plan[d] = DayPlan(
        destinationId: destIdx >= 0 ? dests[destIdx].id : null,
        hotelId: hotels.isNotEmpty ? hotels.first.id : null,
      );
    }
    _dayPlan = plan;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>();
    if (_pkg == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pkg = _pkg!;
    final pkgHotels = trip.hotelsForPackage(pkg);
    final pkgDests = trip.destinationsForPackage(pkg);
    final totalPrice = trip.calcPrice(pkg, _days, _dayPlan);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  TripImage(
                    imageUrl: pkg.image,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.bg],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Badge(pkg.category, AppTheme.primary),
                            const SizedBox(width: 8),
                            if (pkg.difficulty.isNotEmpty)
                              _Badge(pkg.difficulty, AppTheme.accent),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pkg.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            Text(
                              ' ${pkg.city}, ${pkg.country} ',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppTheme.accent,
                            ),
                            Text(
                              ' ${pkg.rating} (${pkg.reviews} reviews)',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary2,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Day Plan'),
                Tab(text: 'Hotels'),
                Tab(text: 'Activities'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _OverviewTab(
                    pkg: pkg,
                    destinations: pkgDests,
                    vendor: _vendor,
                    startDate: _startDate,
                    onDateChanged: (date) => setState(() => _startDate = date),
                  ),
                  _DayPlanTab(
                    pkg: pkg,
                    days: _days,
                    dayPlan: _dayPlan,
                    hotels: pkgHotels,
                    destinations: pkgDests,
                    onDaysChanged: (d) => setState(() {
                      _days = d;
                      _buildDefaultPlan(trip, pkg);
                    }),
                    onPlanChanged: (plan) => setState(() => _dayPlan = plan),
                  ),
                  _HotelsTab(hotels: pkgHotels),
                  _ActivitiesTab(
                    activityIds: pkg.activityIds,
                    selected: _selectedActivities,
                    onToggle: (id) => setState(() {
                      if (_selectedActivities.contains(id)) {
                        _selectedActivities.remove(id);
                      } else {
                        _selectedActivities.add(id);
                      }
                    }),
                  ),
                ],
              ),
            ),

            // Bottom booking bar
            _BookingBar(
              pkg: pkg,
              days: _days,
              totalPrice: totalPrice,
              onBook: () => _handleBook(context),
              loading: _loading,
              notificationsEnabled: _notificationsEnabled,
              onNotificationsChanged: (v) =>
                  setState(() => _notificationsEnabled = v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBook(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      context.push('/login');
      return;
    }

    final trip = context.read<TripProvider>();
    final totalPrice = trip.calcPrice(_pkg!, _days, _dayPlan);

    final paymentMethod = await _showPaymentSheet(context, totalPrice);
    if (paymentMethod == null) return;

    setState(() => _loading = true);
    final bookingId = await trip.createBooking(
      userId: auth.user!.id,
      pkg: _pkg!,
      days: _days,
      dayPlan: _dayPlan,
      activityIds: _selectedActivities,
      totalPrice: totalPrice,
      startDate: _startDate,
      notificationsEnabled: _notificationsEnabled,
    );
    setState(() => _loading = false);
    if (bookingId != null && context.mounted) {
      context.push('/booking/$bookingId');
    }
  }

  Future<String?> _showPaymentSheet(BuildContext context, double amount) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PaymentBottomSheet(amount: amount),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Sub-widgets

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _OverviewTab extends StatelessWidget {
  final PackageModel pkg;
  final List destinations;
  final UserModel? vendor;
  final DateTime startDate;
  final ValueChanged<DateTime> onDateChanged;
  const _OverviewTab({
    required this.pkg,
    required this.destinations,
    this.vendor,
    required this.startDate,
    required this.onDateChanged,
  });
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          pkg.description.isEmpty
              ? 'A wonderful travel experience.'
              : pkg.description,
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickInfo(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: '${pkg.minDays}-${pkg.maxDays} Days',
            ),
            _QuickInfo(
              icon: Icons.trending_up_rounded,
              label: 'Difficulty',
              value: pkg.difficulty,
            ),
            _QuickInfo(
              icon: Icons.wb_sunny_outlined,
              label: 'Weather',
              value: 'Tropical',
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              onDateChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: AppTheme.primary),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Starting Date',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(startDate),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),
                const Text('Change',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (pkg.highlights.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Highlights',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...pkg.highlights.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (vendor != null) ...[
          const SizedBox(height: 24),
          const Text(
            'Organizer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
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
                              vendor!.businessName ?? vendor!.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified_rounded,
                              color: Colors.blue, size: 16),
                        ],
                      ),
                      if (vendor!.businessPhone != null)
                        Text(
                          'Mobile: ${vendor!.businessPhone}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      if (vendor!.businessAddress != null)
                        Text(
                          vendor!.businessAddress!,
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.call_outlined, color: AppTheme.primary),
                  onPressed: () {}, // Could launch url_launcher here
                ),
              ],
            ),
          ),
        ],
        if (destinations.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'Available Destinations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...destinations.map(
            (d) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  TripImage(
                    imageUrl: d.image,
                    width: 60,
                    height: 50,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          d.timeToVisit,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          d.ticketPrice > 0
                              ? '₹${d.ticketPrice} entry'
                              : 'Free entry',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayPlanTab extends StatelessWidget {
  final PackageModel pkg;
  final int days;
  final Map<int, DayPlan> dayPlan;
  final List hotels;
  final List destinations;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<Map<int, DayPlan>> onPlanChanged;
  const _DayPlanTab({
    required this.pkg,
    required this.days,
    required this.dayPlan,
    required this.hotels,
    required this.destinations,
    required this.onDaysChanged,
    required this.onPlanChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Days selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Number of Days',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleBtn(
                    icon: Icons.remove,
                    onTap: () {
                      if (days > pkg.minDays) onDaysChanged(days - 1);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '$days',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  _CircleBtn(
                    icon: Icons.add,
                    onTap: () {
                      if (days < pkg.maxDays) onDaysChanged(days + 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${pkg.minDays}–${pkg.maxDays} days range',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Day cards (Timeline style)
        const SizedBox(height: 8),
        ...List.generate(days, (i) {
          final day = i + 1;
          final isArrival = day == 1;
          final isDeparture = day == days;
          final plan = dayPlan[day];

          final assignedDest = plan?.destinationId == null
              ? null
              : destinations.cast<dynamic>().firstWhere(
                    (d) => d.id == plan?.destinationId,
                    orElse: () => null,
                  );
          final assignedHotel = plan?.hotelId == null
              ? null
              : hotels.cast<dynamic>().firstWhere(
                    (h) => h.id == plan?.hotelId,
                    orElse: () => null,
                  );

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline left part
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isArrival || isDeparture
                              ? AppTheme.accent
                              : AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                      ),
                      if (!isDeparture)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppTheme.border,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Card part
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _DayCard(
                      pkg: pkg,
                      day: day,
                      isArrival: isArrival,
                      isDeparture: isDeparture,
                      assignedDest: assignedDest,
                      assignedHotel: assignedHotel,
                      destinations: destinations,
                      hotels: hotels,
                      dayPlan: dayPlan,
                      onPlanChanged: onPlanChanged,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
      );
}

class _DayCard extends StatefulWidget {
  final PackageModel pkg;
  final int day;
  final bool isArrival, isDeparture;
  final dynamic assignedDest, assignedHotel;
  final List destinations, hotels;
  final Map<int, DayPlan> dayPlan;
  final ValueChanged<Map<int, DayPlan>> onPlanChanged;
  const _DayCard({
    required this.pkg,
    required this.day,
    required this.isArrival,
    required this.isDeparture,
    this.assignedDest,
    this.assignedHotel,
    required this.destinations,
    required this.hotels,
    required this.dayPlan,
    required this.onPlanChanged,
  });
  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded ? AppTheme.primary : AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primary2],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Day ${widget.day}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: widget.isArrival
                ? const Text(
                    '✈️ Arrival Day',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  )
                : widget.isDeparture
                    ? const Text(
                        '🛫 Departure Day',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      )
                    : Text(
                        widget.assignedDest?.name ?? '🌟 Free Day',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            subtitle: widget.assignedHotel != null
                ? Text(
                    '🏨 ${widget.assignedHotel.name}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  )
                : null,
            trailing: _expanded
                ? const Icon(Icons.expand_less, size: 20)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.dayPlan[widget.day]?.arrivalTime != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.dayPlan[widget.day]?.arrivalTime ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.expand_more,
                          size: 20, color: AppTheme.textMuted),
                    ],
                  ),
          ),
          if (_expanded) _buildBody(),
        ],
      ),
    );
  }

  bool _anyMealSelected() {
    final plan = widget.dayPlan[widget.day];
    return (plan?.breakfast ?? false) ||
        (plan?.lunch ?? false) ||
        (plan?.dinner ?? false);
  }

  Widget _MenuRow(String label, String menu) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: AppTheme.primary)),
          Expanded(
              child: Text(menu,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppTheme.border),
          const Text(
            'Destination',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _DestChip(
                  label: '🌟 Free',
                  selected: widget.dayPlan[widget.day]?.destinationId == null,
                  onTap: () {
                    final newPlan = Map<int, DayPlan>.from(widget.dayPlan);
                    final current = newPlan[widget.day];
                    newPlan[widget.day] = DayPlan(
                      destinationId: null,
                      hotelId: current?.hotelId,
                      arrivalTime: current?.arrivalTime,
                      reachingTime: current?.reachingTime,
                    );
                    widget.onPlanChanged(newPlan);
                  },
                ),
                ...widget.destinations.map(
                  (d) => _DestChip(
                    label: d.name,
                    selected: widget.dayPlan[widget.day]?.destinationId == d.id,
                    onTap: () {
                      final newPlan = Map<int, DayPlan>.from(widget.dayPlan);
                      final current = newPlan[widget.day];
                      newPlan[widget.day] = DayPlan(
                        destinationId: d.id,
                        hotelId: current?.hotelId,
                        arrivalTime: current?.arrivalTime,
                        reachingTime: current?.reachingTime,
                      );
                      widget.onPlanChanged(newPlan);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.isArrival || widget.isDeparture) ...[
            Text(
              widget.isArrival ? 'Arrival Schedule' : 'Departure Schedule',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    label: widget.isArrival ? 'Arrival Time' : 'Departure Time',
                    value:
                        widget.dayPlan[widget.day]?.arrivalTime ?? 'Set Time',
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        final newPlan = Map<int, DayPlan>.from(widget.dayPlan);
                        final current = newPlan[widget.day];
                        newPlan[widget.day] = DayPlan(
                          destinationId: current?.destinationId,
                          hotelId: current?.hotelId,
                          arrivalTime: time.format(context),
                          reachingTime: current?.reachingTime,
                        );
                        widget.onPlanChanged(newPlan);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const Text(
            'Included Meals',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MealToggle(
                  label: 'Breakfast',
                  active: widget.dayPlan[widget.day]?.breakfast ?? false,
                  onChanged: (v) {
                    final newPlan = Map<int, DayPlan>.from(widget.dayPlan);
                    final current = newPlan[widget.day];
                    newPlan[widget.day] = DayPlan(
                      destinationId: current?.destinationId,
                      hotelId: current?.hotelId,
                      arrivalTime: current?.arrivalTime,
                      reachingTime: current?.reachingTime,
                      breakfast: v,
                      lunch: current?.lunch ?? false,
                      dinner: current?.dinner ?? false,
                      isCompleted: current?.isCompleted ?? false,
                    );
                    widget.onPlanChanged(newPlan);
                  },
                ),
                const SizedBox(width: 8),
                _MealToggle(
                  label: 'Lunch',
                  active: widget.dayPlan[widget.day]?.lunch ?? false,
                  onChanged: (v) {
                    final newPlan = Map<int, DayPlan>.from(widget.dayPlan);
                    final current = newPlan[widget.day];
                    newPlan[widget.day] = DayPlan(
                      destinationId: current?.destinationId,
                      hotelId: current?.hotelId,
                      arrivalTime: current?.arrivalTime,
                      reachingTime: current?.reachingTime,
                      breakfast: current?.breakfast ?? false,
                      lunch: v,
                      dinner: current?.dinner ?? false,
                      isCompleted: current?.isCompleted ?? false,
                    );
                    widget.onPlanChanged(newPlan);
                  },
                ),
                const SizedBox(width: 8),
                _MealToggle(
                  label: 'Dinner',
                  active: widget.dayPlan[widget.day]?.dinner ?? false,
                  onChanged: (v) {
                    final newPlan = Map<int, DayPlan>.from(widget.dayPlan);
                    final current = newPlan[widget.day];
                    newPlan[widget.day] = DayPlan(
                      destinationId: current?.destinationId,
                      hotelId: current?.hotelId,
                      arrivalTime: current?.arrivalTime,
                      reachingTime: current?.reachingTime,
                      breakfast: current?.breakfast ?? false,
                      lunch: current?.lunch ?? false,
                      dinner: v,
                      isCompleted: current?.isCompleted ?? false,
                    );
                    widget.onPlanChanged(newPlan);
                  },
                ),
              ],
            ),
          ),
          if (_anyMealSelected()) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.dayPlan[widget.day]?.breakfast ?? false)
                    _MenuRow('Breakfast', widget.pkg.breakfastMenu),
                  if (widget.dayPlan[widget.day]?.lunch ?? false)
                    _MenuRow('Lunch', widget.pkg.lunchMenu),
                  if (widget.dayPlan[widget.day]?.dinner ?? false)
                    _MenuRow('Dinner', widget.pkg.dinnerMenu),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Hotel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.hotels.isEmpty)
            const Text(
              'No hotels linked to this package',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            )
          else
            ...widget.hotels.map(
              (h) => GestureDetector(
                onTap: () {
                  final newPlan = Map<int, DayPlan>.from(widget.dayPlan);
                  final current = newPlan[widget.day];
                  newPlan[widget.day] = DayPlan(
                    destinationId: current?.destinationId,
                    hotelId: h.id,
                    arrivalTime: current?.arrivalTime,
                    reachingTime: current?.reachingTime,
                  );
                  widget.onPlanChanged(newPlan);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.dayPlan[widget.day]?.hotelId == h.id
                        ? AppTheme.accent.withOpacity(0.1)
                        : AppTheme.bg2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.dayPlan[widget.day]?.hotelId == h.id
                          ? AppTheme.accent
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      TripImage(
                        imageUrl: h.image,
                        width: 48,
                        height: 40,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${'⭐' * h.stars} · ₹${h.pricePerNight}/night',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.dayPlan[widget.day]?.hotelId == h.id)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : AppTheme.bg2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}

class _HotelsTab extends StatelessWidget {
  final List hotels;
  const _HotelsTab({required this.hotels});
  @override
  Widget build(BuildContext context) {
    if (hotels.isEmpty) {
      return const Center(
        child: Text(
          'No hotels linked',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: hotels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final h = hotels[i];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripImage(
                imageUrl: h.image,
                height: 140,
                width: double.infinity,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            h.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '₹${h.pricePerNight}/night',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('⭐' * h.stars, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      h.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: h.amenities
                          .take(5)
                          .map<Widget>(
                            (a) => Chip(
                              label: Text(
                                a,
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  final List<String> activityIds;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  const _ActivitiesTab({
    required this.activityIds,
    required this.selected,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) {
    if (activityIds.isEmpty) {
      return const Center(
        child: Text(
          'No activities linked',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }
    final trip = context.watch<TripProvider>();
    final linkedActivities =
        trip.activities.where((a) => activityIds.contains(a.id)).toList();

    if (linkedActivities.isEmpty) {
      return const Center(
        child: Text(
          'No activity details found',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: linkedActivities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final a = linkedActivities[i];
        final isSelected = selected.contains(a.id);
        return GestureDetector(
          onTap: () => onToggle(a.id),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                TripImage(
                  imageUrl: a.image,
                  height: 90,
                  width: 90,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          a.category,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${a.price}',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(a.id),
                  activeColor: AppTheme.primary,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MealToggle extends StatelessWidget {
  final String label;
  final bool active;
  final ValueChanged<bool> onChanged;
  const _MealToggle({
    required this.label,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!active),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withOpacity(0.15) : AppTheme.bg2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank,
                size: 14,
                color: active ? AppTheme.primary : AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _TimeBox extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _BookingBar extends StatelessWidget {
  final PackageModel pkg;
  final int days;
  final double totalPrice;
  final VoidCallback onBook;
  final bool loading;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  const _BookingBar({
    required this.pkg,
    required this.days,
    required this.totalPrice,
    required this.onBook,
    required this.loading,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.card,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Enable trip alerts & schedule reminders',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
              SizedBox(
                height: 32,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: notificationsEnabled,
                    onChanged: onNotificationsChanged,
                    activeColor: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppTheme.border),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  Text(
                    '₹${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accent,
                    ),
                  ),
                  Text(
                    '$days days package',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onBook,
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt, size: 18),
                  label: Text(loading ? 'Booking...' : 'Confirm & Pay'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickInfo extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _QuickInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      );
}

class _PaymentBottomSheet extends StatefulWidget {
  final double amount;
  const _PaymentBottomSheet({required this.amount});

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black54, blurRadius: 40, offset: Offset(0, -10))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Methods',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Select your preferred way to pay',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.2),
                      AppTheme.primary.withOpacity(0.05)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary)),
                    Text('₹${widget.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('UPI APPS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          _PaymentOption(
            id: 'gpay',
            name: 'Google Pay',
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.white,
            isSelected: _selectedMethod == 'gpay',
            onTap: () => setState(() => _selectedMethod = 'gpay'),
          ),
          _PaymentOption(
            id: 'phonepe',
            name: 'PhonePe',
            icon: Icons.payments_rounded,
            color: Colors.deepPurpleAccent,
            isSelected: _selectedMethod == 'phonepe',
            onTap: () => setState(() => _selectedMethod = 'phonepe'),
          ),
          _PaymentOption(
            id: 'paytm',
            name: 'Paytm',
            icon: Icons.account_balance_rounded,
            color: Colors.blue,
            isSelected: _selectedMethod == 'paytm',
            onTap: () => setState(() => _selectedMethod = 'paytm'),
          ),
          const SizedBox(height: 24),
          const Text('CARDS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          _PaymentOption(
            id: 'card',
            name: 'Credit / Debit Card',
            icon: Icons.credit_card_rounded,
            color: AppTheme.primary,
            isSelected: _selectedMethod == 'card',
            onTap: () => setState(() => _selectedMethod = 'card'),
          ),
          const SizedBox(height: 40),
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedMethod == null
                    ? null
                    : () => Navigator.pop(context, _selectedMethod),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.primary.withOpacity(0.5),
                ),
                child: const Text('Pay Securely',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String id, name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.bg2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color:
                    isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 24)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.border, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
