import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/package_model.dart';
import '../../models/hotel_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/image_picker_widget.dart';

class AddPackageScreen extends StatefulWidget {
  final String? packageId;
  const AddPackageScreen({super.key, this.packageId});

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name,
      _city,
      _country,
      _imageCtrl,
      _basePrice,
      _minDays,
      _maxDays,
      _rating,
      _description,
      _breakfastMenu,
      _lunchMenu,
      _dinnerMenu;

  late List<String> _hotelIds, _destIds, _activityIds;
  String _category = 'Cultural';
  String _difficulty = 'Easy';
  bool _saving = false;
  bool _initialized = false;

  String _hotelSearch = '';
  String _destSearch = '';
  String _activitySearch = '';

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _city = TextEditingController();
    _country = TextEditingController();
    _imageCtrl = TextEditingController();
    _basePrice = TextEditingController(text: '0');
    _minDays = TextEditingController(text: '3');
    _maxDays = TextEditingController(text: '10');
    _rating = TextEditingController(text: '4.5');
    _description = TextEditingController();
    _breakfastMenu = TextEditingController(text: 'Standard Breakfast');
    _lunchMenu = TextEditingController(text: 'Standard Lunch');
    _dinnerMenu = TextEditingController(text: 'Standard Dinner');
    _hotelIds = [];
    _destIds = [];
    _activityIds = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      if (widget.packageId != null) {
        final trip = context.read<TripProvider>();
        final p = trip.packages.firstWhere((p) => p.id == widget.packageId);
        _name.text = p.name;
        _city.text = p.city;
        _country.text = p.country;
        _imageCtrl.text = p.image;
        _basePrice.text = p.basePrice.toString();
        _minDays.text = p.minDays.toString();
        _maxDays.text = p.maxDays.toString();
        _rating.text = p.rating.toString();
        _description.text = p.description;
        _breakfastMenu.text = p.breakfastMenu;
        _lunchMenu.text = p.lunchMenu;
        _dinnerMenu.text = p.dinnerMenu;
        _category = p.category;
        _difficulty = p.difficulty;
        _hotelIds = List.from(p.hotelIds);
        _destIds = List.from(p.destinationIds);
        _activityIds = List.from(p.activityIds);
      }
      _initialized = true;
    }
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
      _breakfastMenu,
      _lunchMenu,
      _dinnerMenu
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final trip = context.read<TripProvider>();
    final auth = context.read<AuthProvider>();

    // Get existing package to keep its original vendorId if editing
    final existingPkg = widget.packageId != null
        ? trip.packages.firstWhere((p) => p.id == widget.packageId)
        : null;

    final pkg = PackageModel(
      id: widget.packageId ?? '',
      name: _name.text,
      city: _city.text,
      country: _country.text,
      image: _imageCtrl.text,
      basePrice: double.tryParse(_basePrice.text) ?? 0,
      minDays: int.tryParse(_minDays.text) ?? 3,
      maxDays: int.tryParse(_maxDays.text) ?? 10,
      rating: double.tryParse(_rating.text) ?? 4.5,
      reviews: existingPkg?.reviews ?? 0,
      category: _category,
      difficulty: _difficulty,
      description: _description.text,
      vendorId: existingPkg?.vendorId ?? auth.user?.id ?? '',
      breakfastMenu: _breakfastMenu.text,
      lunchMenu: _lunchMenu.text,
      dinnerMenu: _dinnerMenu.text,
      hotelIds: _hotelIds,
      destinationIds: _destIds,
      activityIds: _activityIds,
    );

    try {
      if (widget.packageId == null) {
        await trip.addPackage(pkg);
      } else {
        await trip.updatePackage(widget.packageId!, pkg.toFirestore());
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving package: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.packageId == null ? 'Add Package' : 'Edit Package'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ImagePickerWidget(
              initialUrl: _imageCtrl.text,
              storagePath: 'packages',
              onImageUpload: (url) => setState(() => _imageCtrl.text = url),
            ),
            const SizedBox(height: 20),
            _buildField('Package Name', _name),
            _buildField('City', _city),
            _buildField('Country', _country),
            Row(
              children: [
                Expanded(
                    child: _buildField('Base Price', _basePrice,
                        type: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildField('Rating', _rating,
                        type: TextInputType.number)),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: _buildField('Min Days', _minDays,
                        type: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildField('Max Days', _maxDays,
                        type: TextInputType.number)),
              ],
            ),
            _buildField('Description', _description, maxLines: 4),
            const SizedBox(height: 20),
            const Text('Meal Menu (Fixed)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildField('Breakfast Menu', _breakfastMenu),
            _buildField('Lunch Menu', _lunchMenu),
            _buildField('Dinner Menu', _dinnerMenu),
            const SizedBox(height: 20),
            _buildDropdown(
                'Category',
                _category,
                ['Romance', 'Cultural', 'Luxury', 'Beach', 'Adventure'],
                (v) => setState(() => _category = v!)),
            const SizedBox(height: 12),
            _buildDropdown(
                'Difficulty',
                _difficulty,
                ['Easy', 'Moderate', 'Hard'],
                (v) => setState(() => _difficulty = v!)),
            const SizedBox(height: 30),
            _buildSectionHeader('Link Hotels', _hotelIds.length),
            _buildSearchField(
                'Search hotels...', (v) => setState(() => _hotelSearch = v)),
            _buildHotelList(trip),
            const SizedBox(height: 30),
            _buildSectionHeader('Link Destinations', _destIds.length),
            _buildSearchField('Search destinations...',
                (v) => setState(() => _destSearch = v)),
            _buildDestList(trip),
            const SizedBox(height: 30),
            _buildSectionHeader('Link Activities', _activityIds.length),
            _buildSearchField('Search activities...',
                (v) => setState(() => _activitySearch = v)),
            _buildActivityList(trip),
            const SizedBox(height: 40),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving
                    ? 'Saving...'
                    : (widget.packageId == null
                        ? 'Add Package'
                        : 'Save Changes')),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options,
      ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int selectedCount) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 8),
        Chip(
          label: Text('$selectedCount selected',
              style: const TextStyle(fontSize: 10)),
          visualDensity: VisualDensity.compact,
          backgroundColor: AppTheme.primary.withOpacity(0.1),
        ),
      ],
    );
  }

  Widget _buildSearchField(String hint, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildHotelList(TripProvider trip) {
    final hotels = trip.hotels
        .where((h) =>
            h.name.toLowerCase().contains(_hotelSearch.toLowerCase()) ||
            h.city.toLowerCase().contains(_hotelSearch.toLowerCase()))
        .toList();

    // Group by city
    final grouped = <String, List<HotelModel>>{};
    for (var h in hotels) {
      grouped.putIfAbsent(h.city, () => []).add(h);
    }

    if (hotels.isEmpty) return const _EmptySearch();

    return Column(
      children: grouped.entries
          .map((e) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                    child: Text(e.key.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                            letterSpacing: 1.1)),
                  ),
                  ...e.value.map((h) => CheckboxListTile(
                        title: Text(h.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('⭐' * h.stars + ' · ₹${h.pricePerNight}',
                            style: const TextStyle(fontSize: 11)),
                        value: _hotelIds.contains(h.id),
                        onChanged: (v) => setState(() =>
                            v! ? _hotelIds.add(h.id) : _hotelIds.remove(h.id)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      )),
                ],
              ))
          .toList(),
    );
  }

  Widget _buildDestList(TripProvider trip) {
    final dests = trip.destinations
        .where((d) =>
            d.name.toLowerCase().contains(_destSearch.toLowerCase()) ||
            d.city.toLowerCase().contains(_destSearch.toLowerCase()))
        .toList();

    if (dests.isEmpty) return const _EmptySearch();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dests.length,
      itemBuilder: (context, i) {
        final d = dests[i];
        return CheckboxListTile(
          title: Text(d.name,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(d.city, style: const TextStyle(fontSize: 11)),
          value: _destIds.contains(d.id),
          onChanged: (v) =>
              setState(() => v! ? _destIds.add(d.id) : _destIds.remove(d.id)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      },
    );
  }

  Widget _buildActivityList(TripProvider trip) {
    final activities = trip.activities
        .where((a) =>
            a.name.toLowerCase().contains(_activitySearch.toLowerCase()) ||
            a.city.toLowerCase().contains(_activitySearch.toLowerCase()))
        .toList();

    if (activities.isEmpty) return const _EmptySearch();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, i) {
        final a = activities[i];
        return CheckboxListTile(
          title: Text(a.name,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('${a.city} · ₹${a.price}',
              style: const TextStyle(fontSize: 11)),
          value: _activityIds.contains(a.id),
          onChanged: (v) => setState(
              () => v! ? _activityIds.add(a.id) : _activityIds.remove(a.id)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      },
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
          child: Text('No matches found',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13))),
    );
  }
}
