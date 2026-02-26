import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/package_model.dart';
import '../../models/hotel_model.dart';
import '../../models/destination_model.dart';
import '../../models/activity_model.dart';
import '../../models/booking_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/trip_image.dart';
import '../../providers/theme_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  VENDOR SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class VendorScreen extends StatefulWidget {
  const VendorScreen({super.key});
  @override
  State<VendorScreen> createState() => _VendorScreenState();
}

class _VendorScreenState extends State<VendorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trip = context.watch<TripProvider>();

    if (!auth.isVendor && !auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded,
                  size: 64, color: AppTheme.danger),
              const SizedBox(height: 16),
              const Text('Access Denied',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Vendor privileges required.',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12)),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppTheme.card,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: const Icon(Icons.person_rounded,
                  color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vendor Console',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    auth.user?.name ?? 'Vendor',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, theme, _) => IconButton(
              onPressed: () => theme.toggleTheme(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  theme.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              tooltip: 'Toggle Theme',
            ),
          ),
          IconButton(
            onPressed: () => _tabCtrl.animateTo(6), // Switch to Profile tab
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_rounded,
                  color: AppTheme.primary, size: 18),
            ),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            onPressed: () {
              auth.signOut();
              context.go('/auth');
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppTheme.danger, size: 18),
            ),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(
                text: 'Overview',
                icon: Icon(Icons.dashboard_rounded, size: 16)),
            Tab(text: 'Packages', icon: Icon(Icons.luggage_rounded, size: 16)),
            Tab(text: 'Hotels', icon: Icon(Icons.hotel_rounded, size: 16)),
            Tab(text: 'Dests', icon: Icon(Icons.map_rounded, size: 16)),
            Tab(
                text: 'Acts',
                icon: Icon(Icons.local_activity_rounded, size: 16)),
            Tab(
                text: 'Bookings',
                icon: Icon(Icons.book_online_rounded, size: 16)),
            Tab(
                text: 'Details',
                icon: Icon(Icons.business_center_rounded, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _DashboardTab(trip: trip),
          _PackagesTab(trip: trip),
          _HotelsTab(trip: trip),
          _DestinationsTab(trip: trip),
          _ActivitiesTab(trip: trip),
          _BookingsTab(trip: trip),
          _VendorProfileTab(auth: auth),
        ],
      ),
    );
  }
}

// ── DASHBOARD ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final TripProvider trip;
  const _DashboardTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final vendorPkgs =
        trip.packages.where((p) => p.vendorId == auth.user?.id).length;
    final totalRev =
        trip.vendorBookings.fold<double>(0, (s, b) => s + b.totalPrice);

    final stats = [
      ('Packages', vendorPkgs, Icons.luggage_rounded, AppTheme.primary),
      (
        'Revenue',
        '₹${totalRev.toStringAsFixed(0)}',
        Icons.payments_rounded,
        AppTheme.success
      ),
      (
        'Bookings',
        trip.vendorBookings.length,
        Icons.book_online_rounded,
        AppTheme.accent
      ),
      (
        'Pending',
        trip.vendorBookings.where((b) => b.status != 'confirmed').length,
        Icons.pending_actions_rounded,
        Colors.orangeAccent
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: stats.length,
          itemBuilder: (ctx, i) {
            final s = stats[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                      color: s.$4.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: s.$4.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s.$3, color: s.$4, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1.toString(),
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12)),
                      Text(s.$2.toString(),
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Bookings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            TextButton(onPressed: () {}, child: const Text('View All')),
          ],
        ),
        const SizedBox(height: 12),
        if (trip.vendorBookings.isEmpty)
          const _EmptyTab(
              msg: 'No bookings yet', icon: Icons.receipt_long_rounded)
        else
          ...trip.vendorBookings
              .take(5)
              .map((b) => _BookingItemCard(booking: b)),
      ],
    );
  }
}

class _BookingItemCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingItemCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.confirmation_num_rounded,
                color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.packageName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text('User ID: ${booking.userId}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${booking.totalPrice.toInt()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: AppTheme.primary)),
              const SizedBox(height: 4),
              _StatusChip(status: booking.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == 'confirmed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (active ? AppTheme.success : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: active ? AppTheme.success : Colors.orange),
      ),
    );
  }
}

// ── SHARED: list tab with search bar ─────────────────────────────────────
class _SearchableListTab<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) searchKey; // text to search against
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget addButton;
  final String hint;

  const _SearchableListTab({
    super.key,
    required this.items,
    required this.searchKey,
    required this.itemBuilder,
    required this.addButton,
    required this.hint,
  });

  @override
  State<_SearchableListTab<T>> createState() => _SearchableListTabState<T>();
}

class _SearchableListTabState<T> extends State<_SearchableListTab<T>> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.items
        : widget.items
            .where((item) => widget
                .searchKey(item)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

    return Column(
      children: [
        // ── Search + Add ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AppTheme.textMuted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 16, color: AppTheme.textMuted),
                            onPressed: () => setState(() {
                              _ctrl.clear();
                              _query = '';
                            }),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.addButton,
            ],
          ),
        ),

        // ── Result count ─────────────────────────────────────────
        if (_query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
          ),

        // ── List ─────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 40, color: AppTheme.textMuted),
                      const SizedBox(height: 8),
                      Text(
                        _query.isEmpty ? 'Nothing here yet' : 'No results',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => widget.itemBuilder(ctx, filtered[i]),
                ),
        ),
      ],
    );
  }
}

// ── PACKAGES ─────────────────────────────────────────────────────────────
class _PackagesTab extends StatelessWidget {
  final TripProvider trip;
  const _PackagesTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final vendorPackages =
        trip.packages.where((p) => p.vendorId == auth.user?.id).toList();

    return _SearchableListTab<PackageModel>(
      items: vendorPackages,
      searchKey: (p) => '${p.name} ${p.city} ${p.country} ${p.category}',
      hint: 'Search packages…',
      addButton: ElevatedButton.icon(
        onPressed: () => context.push('/vendor/add-package'),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      itemBuilder: (ctx, p) => _VendorItemTile(
        image: p.image,
        title: p.name,
        subtitle: '${p.city}, ${p.country} · ₹${p.basePrice}',
        badge: p.category,
        onEdit: () => context.push('/vendor/edit-package/${p.id}'),
        onDelete: () => trip.deletePackage(p.id),
      ),
    );
  }
}

// ── HOTELS ───────────────────────────────────────────────────────────────
class _HotelsTab extends StatelessWidget {
  final TripProvider trip;
  const _HotelsTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _SearchableListTab<HotelModel>(
      items: trip.hotels,
      searchKey: (h) => '${h.name} ${h.city}',
      hint: 'Search hotels…',
      addButton: ElevatedButton.icon(
        onPressed: () => _showHotelDialog(context, trip, null),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      itemBuilder: (ctx, h) => _VendorItemTile(
        image: h.image,
        title: h.name,
        subtitle: '${'⭐' * h.stars} · ₹${h.pricePerNight}/night',
        badge: h.city,
        onEdit: () => _showHotelDialog(ctx, trip, h),
        onDelete: () => trip.deleteHotel(h.id),
      ),
    );
  }

  void _showHotelDialog(
      BuildContext context, TripProvider trip, HotelModel? hotel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HotelForm(hotel: hotel, trip: trip),
    );
  }
}

class _HotelForm extends StatefulWidget {
  final HotelModel? hotel;
  final TripProvider trip;
  const _HotelForm({this.hotel, required this.trip});
  @override
  State<_HotelForm> createState() => _HotelFormState();
}

class _HotelFormState extends State<_HotelForm> {
  late final TextEditingController _name,
      _city,
      _imageCtrl,
      _stars,
      _price,
      _rating,
      _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final h = widget.hotel;
    _name = TextEditingController(text: h?.name);
    _city = TextEditingController(text: h?.city);
    _imageCtrl = TextEditingController(text: h?.image);
    _stars = TextEditingController(text: h?.stars.toString() ?? '3');
    _price = TextEditingController(text: h?.pricePerNight.toString() ?? '0');
    _rating = TextEditingController(text: h?.rating.toString() ?? '4.0');
    _description = TextEditingController(text: h?.description);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _city,
      _imageCtrl,
      _stars,
      _price,
      _rating,
      _description
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final h = HotelModel(
      id: widget.hotel?.id ?? '',
      name: _name.text,
      city: _city.text,
      image: _imageCtrl.text,
      stars: int.tryParse(_stars.text) ?? 3,
      pricePerNight: double.tryParse(_price.text) ?? 0,
      rating: double.tryParse(_rating.text) ?? 4.0,
      description: _description.text,
    );
    if (widget.hotel == null) {
      await widget.trip.addHotel(h);
    } else {
      await widget.trip.updateHotel(widget.hotel!.id, h.toFirestore());
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            widget.hotel == null ? 'Add Hotel' : 'Edit Hotel',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          ImagePickerWidget(
            initialUrl: _imageCtrl.text,
            storagePath: 'hotels',
            onImageUpload: (url) => setState(() => _imageCtrl.text = url),
          ),
          const SizedBox(height: 14),
          _Field('Name', _name),
          _Field('City', _city),
          _Field('Stars (1-5)', _stars, type: TextInputType.number),
          _Field('Price/Night', _price, type: TextInputType.number),
          _Field('Rating', _rating, type: TextInputType.number),
          _FieldMulti('Description', _description),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(widget.hotel == null ? 'Add Hotel' : 'Save Changes'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── DESTINATIONS ─────────────────────────────────────────────────────────
class _DestinationsTab extends StatelessWidget {
  final TripProvider trip;
  const _DestinationsTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _SearchableListTab<DestinationModel>(
      items: trip.destinations,
      searchKey: (d) => '${d.name} ${d.city}',
      hint: 'Search destinations…',
      addButton: ElevatedButton.icon(
        onPressed: () => _showDestDialog(context, trip, null),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      itemBuilder: (ctx, d) => _VendorItemTile(
        image: d.image,
        title: d.name,
        subtitle:
            '${d.city} · ${d.ticketPrice > 0 ? "\$${d.ticketPrice}" : "Free"} entry',
        badge: d.city,
        onEdit: () => _showDestDialog(ctx, trip, d),
        onDelete: () => trip.deleteDestination(d.id),
      ),
    );
  }

  void _showDestDialog(
      BuildContext context, TripProvider trip, DestinationModel? dest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DestForm(dest: dest, trip: trip),
    );
  }
}

class _DestForm extends StatefulWidget {
  final DestinationModel? dest;
  final TripProvider trip;
  const _DestForm({this.dest, required this.trip});
  @override
  State<_DestForm> createState() => _DestFormState();
}

class _DestFormState extends State<_DestForm> {
  late final TextEditingController _name,
      _city,
      _imageCtrl,
      _description,
      _ticket,
      _timeToVisit,
      _transport,
      _transportPrice;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.dest;
    _name = TextEditingController(text: d?.name);
    _city = TextEditingController(text: d?.city);
    _imageCtrl = TextEditingController(text: d?.image);
    _description = TextEditingController(text: d?.description);
    _ticket = TextEditingController(text: d?.ticketPrice.toString() ?? '0');
    _timeToVisit = TextEditingController(text: d?.timeToVisit);
    _transport = TextEditingController(text: d?.transport);
    _transportPrice =
        TextEditingController(text: d?.transportPrice.toString() ?? '0');
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _city,
      _imageCtrl,
      _description,
      _ticket,
      _timeToVisit,
      _transport,
      _transportPrice,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final d = DestinationModel(
      id: widget.dest?.id ?? '',
      name: _name.text,
      city: _city.text,
      image: _imageCtrl.text,
      description: _description.text,
      ticketPrice: double.tryParse(_ticket.text) ?? 0,
      timeToVisit: _timeToVisit.text,
      transport: _transport.text,
      transportPrice: double.tryParse(_transportPrice.text) ?? 0,
    );
    if (widget.dest == null) {
      await widget.trip.addDestination(d);
    } else {
      await widget.trip.updateDestination(widget.dest!.id, d.toFirestore());
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            widget.dest == null ? 'Add Destination' : 'Edit Destination',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          ImagePickerWidget(
            initialUrl: _imageCtrl.text,
            storagePath: 'destinations',
            onImageUpload: (url) => setState(() => _imageCtrl.text = url),
          ),
          const SizedBox(height: 14),
          _Field('Name', _name),
          _Field('City', _city),
          _FieldMulti('Description', _description),
          _Field('Ticket Price', _ticket, type: TextInputType.number),
          _Field('Time to Visit', _timeToVisit),
          _Field('Transport', _transport),
          _Field('Transport Price', _transportPrice,
              type: TextInputType.number),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      widget.dest == null ? 'Add Destination' : 'Save Changes'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── ACTIVITIES ───────────────────────────────────────────────────────────
class _ActivitiesTab extends StatelessWidget {
  final TripProvider trip;
  const _ActivitiesTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    return _SearchableListTab<ActivityModel>(
      items: trip.activities,
      searchKey: (a) => '${a.name} ${a.city} ${a.category}',
      hint: 'Search activities…',
      addButton: ElevatedButton.icon(
        onPressed: () => _showActivityDialog(context, trip, null),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      itemBuilder: (ctx, a) => _VendorItemTile(
        image: a.image,
        title: a.name,
        subtitle: '${a.city} · ₹${a.price}',
        badge: a.category,
        onEdit: () => _showActivityDialog(ctx, trip, a),
        onDelete: () => trip.deleteActivity(a.id),
      ),
    );
  }

  void _showActivityDialog(
      BuildContext context, TripProvider trip, ActivityModel? activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ActivityForm(activity: activity, trip: trip),
    );
  }
}

class _ActivityForm extends StatefulWidget {
  final ActivityModel? activity;
  final TripProvider trip;
  const _ActivityForm({this.activity, required this.trip});
  @override
  State<_ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<_ActivityForm> {
  late final TextEditingController _name, _city, _imageCtrl, _price, _desc;
  String _category = 'Sightseeing';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.activity;
    _name = TextEditingController(text: a?.name);
    _city = TextEditingController(text: a?.city);
    _imageCtrl = TextEditingController(text: a?.image);
    _price = TextEditingController(text: a?.price.toString() ?? '0');
    _desc = TextEditingController(text: a?.description);
    _category = a?.category ?? 'Sightseeing';
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _imageCtrl.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final a = ActivityModel(
      id: widget.activity?.id ?? '',
      name: _name.text,
      city: _city.text,
      image: _imageCtrl.text,
      price: double.tryParse(_price.text) ?? 0,
      description: _desc.text,
      category: _category,
    );
    if (widget.activity == null) {
      await widget.trip.addActivity(a);
    } else {
      await widget.trip.updateActivity(widget.activity!.id, a.toFirestore());
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(
            widget.activity == null ? 'Add Activity' : 'Edit Activity',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          ImagePickerWidget(
            initialUrl: _imageCtrl.text,
            storagePath: 'activities',
            onImageUpload: (url) => setState(() => _imageCtrl.text = url),
          ),
          const SizedBox(height: 14),
          _Field('Name', _name),
          _Field('City', _city),
          _Field('Price', _price, type: TextInputType.number),
          _FieldMulti('Description', _desc),
          _DropdownField(
              'Category',
              _category,
              [
                'Sightseeing',
                'Adventure',
                'Cuisine',
                'Culture',
                'Relaxation',
              ],
              (v) => setState(() => _category = v!)),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(widget.activity == null
                      ? 'Add Activity'
                      : 'Save Changes'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── BOOKINGS ─────────────────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  final TripProvider trip;
  const _BookingsTab({required this.trip});

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.trip.vendorBookings
        .where(
            (b) => b.packageName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search bookings...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyTab(
                  msg: 'No bookings found', icon: Icons.receipt_long_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _BookingItemCard(booking: filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String msg;
  final IconData icon;
  const _EmptyTab({required this.msg, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(msg,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════
Widget _Field(
  String label,
  TextEditingController ctrl, {
  TextInputType type = TextInputType.text,
}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
      ),
    );

Widget _FieldMulti(String label, TextEditingController ctrl) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: 3,
        decoration: InputDecoration(labelText: label),
      ),
    );

Widget _DropdownField(
  String label,
  String value,
  List<String> options,
  ValueChanged<String?> onChanged,
) =>
    InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.card,
          isExpanded: true,
          isDense: true,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );

class _VendorItemTile extends StatelessWidget {
  final String image, title, subtitle, badge;
  final VoidCallback onEdit, onDelete;
  const _VendorItemTile({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          TripImage(
            imageUrl: image,
            width: 64,
            height: 64,
            borderRadius: 12,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_note_rounded,
                    color: AppTheme.primary, size: 22),
                onPressed: onEdit,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.danger, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppTheme.card,
                      title: const Text('Confirm Delete'),
                      content: Text('Delete "$title"? This cannot be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          child: const Text('Delete',
                              style: TextStyle(color: AppTheme.danger)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── VENDOR PROFILE ──────────────────────────────────────────────────────────
class _VendorProfileTab extends StatefulWidget {
  final AuthProvider auth;
  const _VendorProfileTab({required this.auth});

  @override
  State<_VendorProfileTab> createState() => _VendorProfileTabState();
}

class _VendorProfileTabState extends State<_VendorProfileTab> {
  late final TextEditingController _name,
      _businessName,
      _businessAddress,
      _businessPhone,
      _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.auth.user;
    _name = TextEditingController(text: u?.name);
    _businessName = TextEditingController(text: u?.businessName);
    _businessAddress = TextEditingController(text: u?.businessAddress);
    _businessPhone = TextEditingController(text: u?.businessPhone);
    _description = TextEditingController(text: u?.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _businessName.dispose();
    _businessAddress.dispose();
    _businessPhone.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final err = await widget.auth.updateProfile(
      name: _name.text,
      businessName: _businessName.text,
      businessAddress: _businessAddress.text,
      businessPhone: _businessPhone.text,
      description: _description.text,
    );
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Profile updated successfully'),
          backgroundColor: err == null ? AppTheme.success : AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Vendor Business Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'These details will be shown to users when they view your items.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        _Field('Display Name', _name),
        _Field('Business Name', _businessName),
        _Field('Business Phone', _businessPhone, type: TextInputType.phone),
        _Field('Business Address', _businessAddress),
        _FieldMulti('Business Description', _description),
        const SizedBox(height: 32),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Business Details'),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 20),
        _buildInfoTile('Email', widget.auth.user?.email ?? 'N/A', Icons.email),
        _buildInfoTile(
            'Vendor Status', 'Verified', Icons.verified_user_rounded),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
