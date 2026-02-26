import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../models/package_model.dart';
import '../models/hotel_model.dart';
import '../models/destination_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'trip_reminders',
          'Trip Reminders',
          channelDescription: 'Notifications for upcoming trip activities',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleTripReminders({
    required BookingModel booking,
    required PackageModel pkg,
    required List<HotelModel> hotels,
    required List<DestinationModel> destinations,
  }) async {
    if (!booking.notificationsEnabled) return;

    // Standard practice: use booking.id hash as a range base
    int baseId = booking.id.hashCode.abs() % 100000;

    int counter = 0;
    for (int dayNum = 1; dayNum <= booking.days; dayNum++) {
      final plan = booking.dayPlan[dayNum];
      if (plan == null) continue;

      final dayDate = booking.startDate.add(Duration(days: dayNum - 1));

      // 1. Transport/Arrival
      _scheduleAtTime(
        id: baseId + (counter++),
        title: 'Morning: Pack & Move',
        body: dayNum == 1
            ? 'Arrive at destination & transfer to hotel. Trip starts!'
            : 'Next: Begin your travel for Day $dayNum.',
        dayDate: dayDate,
        timeString: plan.arrivalTime ?? '09:00 AM',
      );

      // 2. Breakfast
      if (pkg.breakfastMenu.isNotEmpty) {
        _scheduleAtTime(
          id: baseId + (counter++),
          title: 'Morning Meal',
          body: 'Enjoy Breakfast: ${pkg.breakfastMenu}',
          dayDate: dayDate,
          timeString: '08:30 AM',
        );
      }

      // 3. Explore
      if (plan.destinationId != null) {
        final dest =
            destinations.where((d) => d.id == plan.destinationId).firstOrNull;
        if (dest != null) {
          _scheduleAtTime(
            id: baseId + (counter++),
            title: 'What Next: Explore!',
            body: 'Time to visit ${dest.name}. Don\'t miss the views!',
            dayDate: dayDate,
            timeString: '11:00 AM',
          );
        }
      }

      // 4. Lunch
      if (pkg.lunchMenu.isNotEmpty) {
        _scheduleAtTime(
          id: baseId + (counter++),
          title: 'Lunch Break',
          body: 'Mid-day Meal: ${pkg.lunchMenu}',
          dayDate: dayDate,
          timeString: '01:30 PM',
        );
      }

      // 5. Hotel Check-in / Return
      if (plan.hotelId != null) {
        final hotel = hotels.where((h) => h.id == plan.hotelId).firstOrNull;
        if (hotel != null) {
          _scheduleAtTime(
            id: baseId + (counter++),
            title: 'Heading Home',
            body: 'Next: Head to ${hotel.name} for some rest.',
            dayDate: dayDate,
            timeString: plan.reachingTime ?? '04:00 PM',
          );
        }
      }

      // 6. Leisure
      _scheduleAtTime(
        id: baseId + (counter++),
        title: 'Leisure Time',
        body: 'Evening free for local exploration and relaxation.',
        dayDate: dayDate,
        timeString: '06:00 PM',
      );

      // 7. Dinner
      if (pkg.dinnerMenu.isNotEmpty) {
        _scheduleAtTime(
          id: baseId + (counter++),
          title: 'Final Meal of the Day',
          body: 'Tonight\'s Dinner: ${pkg.dinnerMenu}',
          dayDate: dayDate,
          timeString: '08:30 PM',
        );
      }
    }
  }

  void _scheduleAtTime({
    required int id,
    required String title,
    required String body,
    required DateTime dayDate,
    required String timeString,
  }) {
    try {
      final format = DateFormat('hh:mm a');
      final time = format.parse(timeString);

      final scheduledDateTime = DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
        time.hour,
        time.minute,
      ).subtract(const Duration(minutes: 15)); // 15 mins before

      scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledDateTime,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
