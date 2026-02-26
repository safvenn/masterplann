import 'package:cloud_firestore/cloud_firestore.dart';

class DayPlan {
  final String? destinationId;
  final String? hotelId;
  final String? arrivalTime; // e.g. "09:00 AM"
  final String? reachingTime; // e.g. "05:00 PM"
  final bool isCompleted;
  final bool breakfast;
  final bool lunch;
  final bool dinner;
  final bool breakfastCompleted;
  final bool lunchCompleted;
  final bool dinnerCompleted;

  DayPlan({
    this.destinationId,
    this.hotelId,
    this.arrivalTime,
    this.reachingTime,
    this.isCompleted = false,
    this.breakfast = false,
    this.lunch = false,
    this.dinner = false,
    this.breakfastCompleted = false,
    this.lunchCompleted = false,
    this.dinnerCompleted = false,
  });

  factory DayPlan.fromMap(Map<String, dynamic> m) => DayPlan(
        destinationId: m['destinationId'],
        hotelId: m['hotelId'],
        arrivalTime: m['arrivalTime'],
        reachingTime: m['reachingTime'],
        isCompleted: m['isCompleted'] ?? false,
        breakfast: m['breakfast'] ?? false,
        lunch: m['lunch'] ?? false,
        dinner: m['dinner'] ?? false,
        breakfastCompleted: m['breakfastCompleted'] ?? false,
        lunchCompleted: m['lunchCompleted'] ?? false,
        dinnerCompleted: m['dinnerCompleted'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'destinationId': destinationId,
        'hotelId': hotelId,
        'arrivalTime': arrivalTime,
        'reachingTime': reachingTime,
        'isCompleted': isCompleted,
        'breakfast': breakfast,
        'lunch': lunch,
        'dinner': dinner,
        'breakfastCompleted': breakfastCompleted,
        'lunchCompleted': lunchCompleted,
        'dinnerCompleted': dinnerCompleted,
      };
}

class BookingModel {
  final String id;
  final String userId;
  final String packageId;
  final String vendorId;
  final String packageName;
  final String packageCity;
  final String packageImage;
  final int days;
  final Map<int, DayPlan> dayPlan;
  final List<String> activityIds;
  final double totalPrice;
  final String status;
  final DateTime bookedAt;
  final DateTime startDate;
  final bool notificationsEnabled;

  BookingModel({
    required this.id,
    required this.userId,
    required this.packageId,
    this.vendorId = '',
    required this.packageName,
    required this.packageCity,
    required this.packageImage,
    required this.days,
    required this.dayPlan,
    required this.activityIds,
    required this.totalPrice,
    required this.status,
    required this.bookedAt,
    required this.startDate,
    this.notificationsEnabled = true,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final dayPlanRaw = (d['dayPlan'] as Map<String, dynamic>?) ?? {};
    final dayPlanParsed = <int, DayPlan>{};
    dayPlanRaw.forEach((k, v) {
      dayPlanParsed[int.parse(k)] = DayPlan.fromMap(
        Map<String, dynamic>.from(v),
      );
    });
    return BookingModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      packageId: d['packageId'] ?? '',
      vendorId: d['vendorId'] ?? '',
      packageName: d['packageName'] ?? '',
      packageCity: d['packageCity'] ?? '',
      packageImage: d['packageImage'] ?? '',
      days: (d['days'] ?? 1).toInt(),
      dayPlan: dayPlanParsed,
      activityIds: List<String>.from(d['activityIds'] ?? []),
      totalPrice: (d['totalPrice'] ?? 0).toDouble(),
      status: d['status'] ?? 'confirmed',
      bookedAt: (d['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (d['startDate'] as Timestamp?)?.toDate() ??
          (d['bookedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      notificationsEnabled: d['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    final dayPlanMap = <String, dynamic>{};
    dayPlan.forEach((k, v) => dayPlanMap[k.toString()] = v.toMap());
    return {
      'userId': userId,
      'packageId': packageId,
      'vendorId': vendorId,
      'packageName': packageName,
      'packageCity': packageCity,
      'packageImage': packageImage,
      'days': days,
      'dayPlan': dayPlanMap,
      'activityIds': activityIds,
      'totalPrice': totalPrice,
      'status': status,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'startDate': Timestamp.fromDate(startDate),
      'notificationsEnabled': notificationsEnabled,
    };
  }
}
