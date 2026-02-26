import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide ChangeNotifierProvider, Provider, Consumer;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/trip_provider.dart';
import 'utils/app_theme.dart';
import 'router.dart';
import 'services/notification_service.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: TripPlannerApp(),
    ),
  );
}
//io

class TripPlannerApp extends StatelessWidget {
  const TripPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TripProvider>(
          create: (_) => TripProvider(),
          update: (_, auth, trip) {
            trip ??= TripProvider();
            trip.init(
              auth.user?.id,
              isAdmin: auth.isAdmin,
              isVendor: auth.isVendor,
            );
            return trip;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context);
          return MaterialApp.router(
            title: 'Roads to go',
            theme: AppTheme.dark,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
