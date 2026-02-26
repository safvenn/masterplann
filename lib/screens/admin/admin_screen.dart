import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/package_model.dart';
import '../../models/hotel_model.dart';
import '../../models/destination_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/trip_image.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ADMIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trip = context.watch<TripProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad_rounded,
                  size: 54, color: AppTheme.danger),
              const SizedBox(height: 12),
              const Text('Access Denied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('You need admin privileges',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Tab bar ───────────────────────────────────────────────
          Container(
            color: AppTheme.card,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _AdminTab('Dashboard', Icons.dashboard_rounded, 0, _tab,
                      (i) => setState(() => _tab = i)),
                  _AdminTab('Packages', Icons.luggage_rounded, 1, _tab,
                      (i) => setState(() => _tab = i)),
                  _AdminTab('Hotels', Icons.hotel_rounded, 2, _tab,
                      (i) => setState(() => _tab = i)),
                  _AdminTab('Destinations', Icons.location_on_rounded, 3, _tab,
                      (i) => setState(() => _tab = i)),
                  _AdminTab('Bookings', Icons.book_online_rounded, 4, _tab,
                      (i) => setState(() => _tab = i)),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _DashboardTab(trip: trip),
                _PackagesTab(trip: trip),
                _HotelsTab(trip: trip),
                _DestinationsTab(trip: trip),
                _BookingsTab(trip: trip),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final int index, current;
  final ValueChanged<int> onTap;
  const _AdminTab(this.label, this.icon, this.index, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    final totalRev = trip.bookings.fold<double>(0, (s, b) => s + b.totalPrice);
    final stats = [
      (
        'Packages',
        trip.packages.length,
        Icons.luggage_rounded,
        AppTheme.primary
      ),
      ('Hotels', trip.hotels.length, Icons.hotel_rounded, AppTheme.accent),
      (
        'Destinations',
        trip.destinations.length,
        Icons.location_on_rounded,
        AppTheme.success
      ),
      (
        'Bookings',
        trip.bookings.length,
        Icons.book_online_rounded,
        Colors.pinkAccent
      ),
      (
        '₹${totalRev.toStringAsFixed(0)}',
        'Revenue',
        Icons.trending_up_rounded,
        Colors.blueAccent
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: stats
              .map((s) => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (s.$4 as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.$3 as IconData,
                              color: s.$4 as Color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                s.$1.toString(),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                s.$2.toString(),
                                style: const TextStyle(
                                    color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        const Text('Recent Bookings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...trip.bookings.take(5).map(
              (b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(b.packageName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text('${b.days} days',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(width: 10),
                    Text('₹${b.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Chip(
                      label:
                          Text(b.status, style: const TextStyle(fontSize: 10)),
                      backgroundColor: AppTheme.success.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
            ),
      ],
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
    return _SearchableListTab<PackageModel>(
      items: trip.packages,
      searchKey: (p) => '${p.name} ${p.city} ${p.country} ${p.category}',
      hint: 'Search packages…',
      addButton: ElevatedButton.icon(
        onPressed: () => _showPackageDialog(context, trip, null),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      itemBuilder: (ctx, p) => _AdminItemTile(
        image: p.image,
        title: p.name,
        subtitle: '${p.city}, ${p.country} · ₹${p.basePrice}',
        badge: p.category,
        onEdit: () => _showPackageDialog(ctx, trip, p),
        onDelete: () => trip.deletePackage(p.id),
      ),
    );
  }

  void _showPackageDialog(
      BuildContext context, TripProvider trip, PackageModel? pkg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PackageForm(pkg: pkg, trip: trip),
    );
  }
}

class _PackageForm extends StatefulWidget {
  final PackageModel? pkg;
  final TripProvider trip;
  const _PackageForm({this.pkg, required this.trip});
  @override
  State<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<_PackageForm> {
  late final TextEditingController _name,
      _city,
      _country,
      _imageCtrl,
      _basePrice,
      _minDays,
      _maxDays,
      _rating,
      _description;
  late List<String> _hotelIds, _destIds, _activityIds;
  String _category = 'Cultural';
  String _difficulty = 'Easy';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pkg;
    _name = TextEditingController(text: p?.name);
    _city = TextEditingController(text: p?.city);
    _country = TextEditingController(text: p?.country);
    _imageCtrl = TextEditingController(text: p?.image);
    _basePrice = TextEditingController(text: p?.basePrice.toString() ?? '0');
    _minDays = TextEditingController(text: p?.minDays.toString() ?? '3');
    _maxDays = TextEditingController(text: p?.maxDays.toString() ?? '10');
    _rating = TextEditingController(text: p?.rating.toString() ?? '4.5');
    _description = TextEditingController(text: p?.description);
    _category = p?.category ?? 'Cultural';
    _difficulty = p?.difficulty ?? 'Easy';
    _hotelIds = List.from(p?.hotelIds ?? []);
    _destIds = List.from(p?.destinationIds ?? []);
    _activityIds = List.from(p?.activityIds ?? []);
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _city,
      _country,
      _imageCtrl,
      _basePrice,
      _minDays,
      _maxDays,
      _rating,
      _description,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final pkg = PackageModel(
      id: widget.pkg?.id ?? '',
      name: _name.text,
      city: _city.text,
      country: _country.text,
      image: _imageCtrl.text,
      basePrice: double.tryParse(_basePrice.text) ?? 0,
      minDays: int.tryParse(_minDays.text) ?? 3,
      maxDays: int.tryParse(_maxDays.text) ?? 10,
      rating: double.tryParse(_rating.text) ?? 4.5,
      reviews: widget.pkg?.reviews ?? 0,
      category: _category,
      difficulty: _difficulty,
      description: _description.text,
      hotelIds: _hotelIds,
      destinationIds: _destIds,
      activityIds: _activityIds,
    );
    if (widget.pkg == null) {
      await widget.trip.addPackage(pkg);
    } else {
      await widget.trip.updatePackage(widget.pkg!.id, pkg.toFirestore());
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
          // Handle
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
            widget.pkg == null ? 'Add Package' : 'Edit Package',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),

          ImagePickerWidget(
            initialUrl: _imageCtrl.text,
            storagePath: 'packages',
            onImageUpload: (url) => setState(() => _imageCtrl.text = url),
          ),
          const SizedBox(height: 14),

          _Field('Name', _name),
          _Field('City', _city),
          _Field('Country', _country),
          _Field('Base Price', _basePrice, type: TextInputType.number),
          _Field('Min Days', _minDays, type: TextInputType.number),
          _Field('Max Days', _maxDays, type: TextInputType.number),
          _Field('Rating', _rating, type: TextInputType.number),
          _FieldMulti('Description', _description),

          const SizedBox(height: 4),
          _DropdownField(
              'Category',
              _category,
              [
                'Romance',
                'Cultural',
                'Luxury',
                'Beach',
                'Adventure',
              ],
              (v) => setState(() => _category = v!)),
          const SizedBox(height: 12),
          _DropdownField(
              'Difficulty',
              _difficulty,
              [
                'Easy',
                'Moderate',
                'Hard',
              ],
              (v) => setState(() => _difficulty = v!)),
          const SizedBox(height: 20),

          // Link hotels
          _LinkSection(
            title: 'Link Hotels',
            allItems: widget.trip.hotels
                .map((h) => _LinkItem(
                    id: h.id,
                    name: h.name,
                    subtitle: '\$${h.pricePerNight}/night'))
                .toList(),
            selectedIds: _hotelIds,
            onToggle: (id) => setState(() {
              _hotelIds.contains(id) ? _hotelIds.remove(id) : _hotelIds.add(id);
            }),
          ),
          const SizedBox(height: 12),
          _LinkSection(
            title: 'Link Destinations',
            allItems: widget.trip.destinations
                .map((d) => _LinkItem(id: d.id, name: d.name, subtitle: d.city))
                .toList(),
            selectedIds: _destIds,
            onToggle: (id) => setState(() {
              _destIds.contains(id) ? _destIds.remove(id) : _destIds.add(id);
            }),
          ),
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.pkg == null ? 'Add Package' : 'Save Changes'),
            ),
          ),
          const SizedBox(height: 12),
        ],
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
      itemBuilder: (ctx, h) => _AdminItemTile(
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
      itemBuilder: (ctx, d) => _AdminItemTile(
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

// ── BOOKINGS ─────────────────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  final TripProvider trip;
  const _BookingsTab({required this.trip});
  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.trip.bookings;
    final filtered = _query.isEmpty
        ? all
        : all
            .where((b) =>
                b.packageName.toLowerCase().contains(_query.toLowerCase()) ||
                b.status.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _ctrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search bookings…',
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        if (filtered.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No bookings found',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final b = filtered[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.packageName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(
                              '${b.days} days · ₹${b.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(b.status,
                            style: const TextStyle(fontSize: 10)),
                        backgroundColor: AppTheme.success.withOpacity(0.2),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded,
                            size: 18, color: AppTheme.danger),
                        onPressed: () =>
                            _confirmDelete(context, b.id, b.packageName),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Booking?'),
        content:
            Text('Are you sure you want to delete the booking for "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.trip.deleteBooking(id);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
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

class _LinkItem {
  final String id, name, subtitle;
  _LinkItem({required this.id, required this.name, required this.subtitle});
}

class _LinkSection extends StatelessWidget {
  final String title;
  final List<_LinkItem> allItems;
  final List<String> selectedIds;
  final ValueChanged<String> onToggle;
  const _LinkSection({
    required this.title,
    required this.allItems,
    required this.selectedIds,
    required this.onToggle,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 8),
              Chip(
                label: Text('${selectedIds.length} selected',
                    style: const TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (allItems.isEmpty)
            const Text('None available — add them first',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12))
          else
            ...allItems.map((item) {
              final sel = selectedIds.contains(item.id);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  value: sel,
                  onChanged: (_) => onToggle(item.id),
                  activeColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                title: Text(item.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle:
                    Text(item.subtitle, style: const TextStyle(fontSize: 11)),
                onTap: () => onToggle(item.id),
              );
            }),
        ],
      );
}

class _AdminItemTile extends StatelessWidget {
  final String image, title, subtitle, badge;
  final VoidCallback onEdit, onDelete;
  const _AdminItemTile({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onEdit,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            TripImage(
              imageUrl: image,
              width: 52,
              height: 52,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: AppTheme.primary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded,
                  size: 18, color: AppTheme.danger),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppTheme.card,
                    title: const Text('Delete?'),
                    content: Text('Delete "$title"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
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
      );
}
