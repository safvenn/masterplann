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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
            if (auth.isLoggedIn) {
              trip.init(auth.user?.id);
            } else {
              trip.init(null);
            }
            return trip;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(context);
          return MaterialApp.router(
            title: 'Trip Planner',
            theme: AppTheme.dark,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
