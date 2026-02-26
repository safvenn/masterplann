import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/package/package_detail_screen.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/booking/my_bookings_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/admin/vendor_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/admin/add_package_screen.dart';
import 'screens/admin/admin_dashboard.dart';

GoRouter buildRouter(BuildContext context) {
  final authProvider = context.read<AuthProvider>();

  return GoRouter(
    initialLocation: '/',
    // Rebuild router when auth state changes
    refreshListenable: authProvider,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final location = state.matchedLocation;
      final isAuthPage = location == '/login' ||
          location == '/register' ||
          location == '/auth';

      final isProtected = location.startsWith('/my-bookings') ||
          location.startsWith('/booking') ||
          location.startsWith('/vendor') ||
          location.startsWith('/admin') ||
          location == '/profile';

      // Still loading — wait
      if (auth.status == AuthStatus.unknown) return null;

      // Not logged in and trying to access protected page
      if (!auth.isLoggedIn && isProtected) return '/login';

      // Admin area protection
      if (location.startsWith('/admin') && !auth.isAdmin) return '/';

      // Vendor area protection
      if (location.startsWith('/vendor') && !auth.isVendor && !auth.isAdmin)
        return '/';

      // Logged in but on auth pages or home — go to specific dashboard if vendor
      if (auth.isLoggedIn && (isAuthPage || location == '/')) {
        if (auth.isVendor && !auth.isAdmin) return '/vendor';
        return location == '/' ? null : '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
      GoRoute(
        path: '/package/:id',
        builder: (c, s) =>
            PackageDetailScreen(packageId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (c, s) => BookingScreen(bookingId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (c, s) => const MyBookingsScreen(),
      ),
      GoRoute(path: '/login', builder: (c, s) => const AuthScreen()),
      GoRoute(
          path: '/register',
          builder: (c, s) => const AuthScreen(initialTab: 1)),
      GoRoute(path: '/auth', builder: (c, s) => const AuthScreen()),
      GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      GoRoute(path: '/vendor', builder: (c, s) => const VendorScreen()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminDashboard()),
      GoRoute(
        path: '/vendor/add-package',
        builder: (c, s) => const AddPackageScreen(),
      ),
      GoRoute(
        path: '/vendor/edit-package/:id',
        builder: (c, s) => AddPackageScreen(packageId: s.pathParameters['id']),
      ),
    ],
  );
}
