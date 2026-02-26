import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/package/package_detail_screen.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/booking/my_bookings_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/profile/profile_screen.dart';

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
          location == '/admin' ||
          location == '/profile';

      // Still loading — wait
      if (auth.status == AuthStatus.unknown) return null;

      // Not logged in and trying to access protected page
      if (!auth.isLoggedIn && isProtected) return '/login';

      // Logged in but on auth pages — go home
      // Don't redirect from auth pages during sign-in (let the screen handle it)
      // Only redirect if already logged in BEFORE visiting the page
      if (auth.isLoggedIn && isAuthPage) return '/';

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
      GoRoute(path: '/admin', builder: (c, s) => const AdminScreen()),
    ],
  );
}
