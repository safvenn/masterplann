import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>();
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Access Denied',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Admin Console'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.people_alt_rounded, size: 18)),
            Tab(text: 'Packages', icon: Icon(Icons.luggage_rounded, size: 18)),
            Tab(
                text: 'Bookings',
                icon: Icon(Icons.book_online_rounded, size: 18)),
            Tab(text: 'Hotels', icon: Icon(Icons.hotel_rounded, size: 18)),
            Tab(text: 'Destinations', icon: Icon(Icons.map_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _UsersTab(trip: trip),
          _AdminPackagesTab(trip: trip),
          _AdminBookingsTab(trip: trip),
          _AdminHotelsTab(trip: trip),
          _AdminDestinationsTab(trip: trip),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: child,
    );
  }
}

Future<bool> _showConfirm(
    BuildContext context, String title, String content) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

class _UsersTab extends StatelessWidget {
  final TripProvider trip;
  const _UsersTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final users = trip.users;
    if (users.isEmpty) return const _EmptyState(msg: 'No users found');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        return _SectionCard(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child:
                  Icon(Icons.person_outline_rounded, color: AppTheme.primary),
            ),
            title: Text(u['name'] ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(u['email'] ?? 'No email',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Wrap(
              spacing: 4,
              children: [
                _RoleChip(
                  label: 'Vendor',
                  active: u['isVendor'] ?? false,
                  onToggle: (v) => trip.updateUserRole(u['id'], isVendor: v),
                ),
                _RoleChip(
                  label: 'Admin',
                  active: u['isAdmin'] ?? false,
                  onToggle: (v) => trip.updateUserRole(u['id'], isAdmin: v),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.danger),
                  onPressed: () async {
                    if (await _showConfirm(context, 'Delete User',
                        'Are you sure you want to delete "${u['name']}"? This cannot be undone.')) {
                      trip.deleteUser(u['id']);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool active;
  final ValueChanged<bool> onToggle;

  const _RoleChip(
      {required this.label, required this.active, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 10,
              color: active ? AppTheme.primary : AppTheme.textMuted)),
      selected: active,
      onSelected: onToggle,
      visualDensity: VisualDensity.compact,
      selectedColor: AppTheme.primary.withOpacity(0.15),
      checkmarkColor: AppTheme.primary,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: active ? AppTheme.primary : AppTheme.border),
      padding: EdgeInsets.zero,
    );
  }
}

class _AdminPackagesTab extends StatelessWidget {
  final TripProvider trip;
  const _AdminPackagesTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final pkgs = trip.packages;
    if (pkgs.isEmpty) return const _EmptyState(msg: 'No packages found');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: pkgs.length,
      itemBuilder: (context, i) {
        final p = pkgs[i];
        return _SectionCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(p.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported)),
            ),
            title: Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.city}, ${p.country}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('Vendor ID: ${p.vendorId}',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger),
              onPressed: () async {
                if (await _showConfirm(context, 'Delete Package',
                    'Are you sure you want to delete "${p.name}"?')) {
                  trip.deletePackage(p.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _AdminBookingsTab extends StatelessWidget {
  final TripProvider trip;
  const _AdminBookingsTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final bookings = trip.bookings;
    if (bookings.isEmpty) return const _EmptyState(msg: 'No bookings found');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: bookings.length,
      itemBuilder: (context, i) {
        final b = bookings[i];
        return _SectionCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(b.packageName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${b.status.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 11,
                        color: b.status == 'confirmed'
                            ? AppTheme.success
                            : AppTheme.accent,
                        fontWeight: FontWeight.bold)),
                Text('User: ${b.userId}',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${b.totalPrice.toInt()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppTheme.primary)),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded,
                      size: 20, color: AppTheme.danger),
                  onPressed: () async {
                    if (await _showConfirm(context, 'Delete Booking',
                        'Remove this booking record?')) {
                      trip.deleteBooking(b.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminHotelsTab extends StatelessWidget {
  final TripProvider trip;
  const _AdminHotelsTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final hotels = trip.hotels;
    if (hotels.isEmpty) return const _EmptyState(msg: 'No hotels found');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: hotels.length,
      itemBuilder: (context, i) {
        final h = hotels[i];
        return _SectionCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(h.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.hotel_rounded)),
            ),
            title: Text(h.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${h.city} · ${h.stars} Stars',
                style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger),
              onPressed: () async {
                if (await _showConfirm(
                    context, 'Delete Hotel', 'Delete hotel "${h.name}"?')) {
                  trip.deleteHotel(h.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _AdminDestinationsTab extends StatelessWidget {
  final TripProvider trip;
  const _AdminDestinationsTab({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dests = trip.destinations;
    if (dests.isEmpty) return const _EmptyState(msg: 'No destinations found');

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: dests.length,
      itemBuilder: (context, i) {
        final d = dests[i];
        return _SectionCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(d.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.place_rounded)),
            ),
            title: Text(d.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(d.city, style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.danger),
              onPressed: () async {
                if (await _showConfirm(
                    context, 'Delete Destination', 'Delete "${d.name}"?')) {
                  trip.deleteDestination(d.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String msg;
  const _EmptyState({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppTheme.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(msg,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }
}
