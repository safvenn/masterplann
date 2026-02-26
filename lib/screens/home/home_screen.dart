import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/package_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/trip_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String _category = 'All';
  String _sort = 'rating';
  final _searchCtrl = TextEditingController();

  final _categories = [
    'All',
    'Romance',
    'Cultural',
    'Luxury',
    'Beach',
    'Adventure',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trip = context.watch<TripProvider>();

    List<PackageModel> filtered = trip.packages
        .where(
          (p) =>
              (_category == 'All' || p.category == _category) &&
              (p.name.toLowerCase().contains(_search.toLowerCase()) ||
                  p.city.toLowerCase().contains(_search.toLowerCase()) ||
                  p.country.toLowerCase().contains(_search.toLowerCase())),
        )
        .toList();

    filtered.sort((a, b) {
      if (_sort == 'price') return a.basePrice.compareTo(b.basePrice);
      if (_sort == 'rating') return b.rating.compareTo(a.rating);
      if (_sort == 'reviews') return b.reviews.compareTo(a.reviews);
      return 0;
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.bg,
            flexibleSpace: FlexibleSpaceBar(background: _buildHero()),
            actions: [
              if (auth.isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  onPressed: () => context.push('/admin'),
                ),
              if (auth.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.bookmark_rounded),
                  onPressed: () => context.push('/my-bookings'),
                )
              else
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Sign In'),
                ),
              if (auth.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 4),
                  child: GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Tooltip(
                      message: 'Profile',
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.primary2],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            auth.user?.name.isNotEmpty == true
                                ? auth.user!.name
                                    .trim()
                                    .split(' ')
                                    .map((w) => w[0])
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Search bar
          SliverToBoxAdapter(child: _buildSearchBar()),

          // Category chips
          SliverToBoxAdapter(child: _buildCategories()),

          // Sort + count row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} Packages',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  _SortDropdown(
                    value: _sort,
                    onChanged: (v) => setState(() => _sort = v),
                  ),
                ],
              ),
            ),
          ),

          // Package Grid
          filtered.isEmpty
              ? SliverFillRemaining(child: _buildEmpty())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisExtent: 340,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => PackageCard(pkg: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a3e), Color(0xFF0f0f1a)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 13, color: AppTheme.primary2),
                SizedBox(width: 6),
                Text(
                  'Premium Trip Planner',
                  style: TextStyle(
                    color: AppTheme.primary2,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              children: [
                const TextSpan(
                  text: 'Discover Your\n',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                TextSpan(
                  text: 'Dream Journey',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary2],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Curated packages with real-time itinerary tracking',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search destinations, packages...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textMuted,
          ),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = _category == cat;
          return GestureDetector(
            onTap: () => setState(() => _category = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.bg2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'No packages found',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Try adjusting your search',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          dropdownColor: AppTheme.card,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'rating', child: Text('Best Rating')),
            DropdownMenuItem(value: 'price', child: Text('Lowest Price')),
            DropdownMenuItem(value: 'reviews', child: Text('Most Reviews')),
          ],
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}

class PackageCard extends StatefulWidget {
  final PackageModel pkg;
  const PackageCard({super.key, required this.pkg});
  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  bool _wishlisted = false;

  @override
  Widget build(BuildContext context) {
    final pkg = widget.pkg;
    return GestureDetector(
      onTap: () => context.push('/package/${pkg.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TripImage(
                    imageUrl: pkg.image,
                    fit: BoxFit.cover,
                  ),
                  // Category badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pkg.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Wishlist
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _wishlisted = !_wishlisted),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.bg.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _wishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: _wishlisted
                              ? Colors.redAccent
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  // Difficulty
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bg.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pkg.difficulty,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${pkg.city}, ${pkg.country}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pkg.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          pkg.rating.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${pkg.reviews})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${pkg.minDays}-${pkg.maxDays}d',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'From',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '₹${pkg.basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primary2],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Explore',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
