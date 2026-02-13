import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AnalyticsData {
  final int totalStudents;
  final int totalSubscriptions;
  final int totalSemesters;
  final int totalBusStops;

  final int pendingSubscriptions;
  final int approvedSubscriptions;
  final int rejectedSubscriptions;
  final int expiredSubscriptions;

  final Map<String, int> subscriptionsBySemester;
  final Map<String, int> subscriptionsByStatus;
  final Map<int, int> subscriptionsByYear;

  final List<Map<String, dynamic>> recentSubscriptions;
  final List<Map<String, dynamic>> topBusStops;

  // Trend data
  final double studentsWeeklyChange;
  final double studentsMonthlyChange;
  final double studentsSemesterChange;
  final double subscriptionsWeeklyChange;
  final double subscriptionsMonthlyChange;
  final double subscriptionsSemesterChange;

  // Semester analytics for current year
  final Map<String, Map<String, dynamic>> semesterAnalytics;

  AnalyticsData({
    required this.totalStudents,
    required this.totalSubscriptions,
    required this.totalSemesters,
    required this.totalBusStops,
    required this.pendingSubscriptions,
    required this.approvedSubscriptions,
    required this.rejectedSubscriptions,
    required this.expiredSubscriptions,
    required this.subscriptionsBySemester,
    required this.subscriptionsByStatus,
    required this.subscriptionsByYear,
    required this.recentSubscriptions,
    required this.topBusStops,
    required this.studentsWeeklyChange,
    required this.studentsMonthlyChange,
    required this.studentsSemesterChange,
    required this.subscriptionsWeeklyChange,
    required this.subscriptionsMonthlyChange,
    required this.subscriptionsSemesterChange,
    required this.semesterAnalytics,
  });

  factory AnalyticsData.empty() {
    return AnalyticsData(
      totalStudents: 0,
      totalSubscriptions: 0,
      totalSemesters: 0,
      totalBusStops: 0,
      pendingSubscriptions: 0,
      approvedSubscriptions: 0,
      rejectedSubscriptions: 0,
      expiredSubscriptions: 0,
      subscriptionsBySemester: {},
      subscriptionsByStatus: {},
      subscriptionsByYear: {},
      recentSubscriptions: [],
      topBusStops: [],
      studentsWeeklyChange: 0.0,
      studentsMonthlyChange: 0.0,
      studentsSemesterChange: 0.0,
      subscriptionsWeeklyChange: 0.0,
      subscriptionsMonthlyChange: 0.0,
      subscriptionsSemesterChange: 0.0,
      semesterAnalytics: {},
    );
  }
}

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch comprehensive analytics data
  Future<AnalyticsData> fetchAnalytics() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _fetchTotalStudents(),
        _fetchSubscriptionStats(),
        _fetchTotalSemesters(),
        _fetchTotalBusStops(),
        _fetchRecentSubscriptions(),
        _fetchTopBusStops(),
        _fetchTrendData(),
        _fetchSemesterAnalytics(),
      ]);

      final subscriptionStats = results[1] as Map<String, dynamic>;
      final trendData = results[6] as Map<String, double>;
      final semesterAnalytics = results[7] as Map<String, Map<String, dynamic>>;

      return AnalyticsData(
        totalStudents: results[0] as int,
        totalSubscriptions: subscriptionStats['total'] as int,
        totalSemesters: results[2] as int,
        totalBusStops: results[3] as int,
        pendingSubscriptions: subscriptionStats['pending'] as int,
        approvedSubscriptions: subscriptionStats['approved'] as int,
        rejectedSubscriptions: subscriptionStats['rejected'] as int,
        expiredSubscriptions: subscriptionStats['expired'] as int,
        subscriptionsBySemester:
            subscriptionStats['bySemester'] as Map<String, int>,
        subscriptionsByStatus:
            subscriptionStats['byStatus'] as Map<String, int>,
        subscriptionsByYear: subscriptionStats['byYear'] as Map<int, int>,
        recentSubscriptions: results[4] as List<Map<String, dynamic>>,
        topBusStops: results[5] as List<Map<String, dynamic>>,
        studentsWeeklyChange: trendData['studentsWeekly'] ?? 0.0,
        studentsMonthlyChange: trendData['studentsMonthly'] ?? 0.0,
        studentsSemesterChange: trendData['studentsSemester'] ?? 0.0,
        subscriptionsWeeklyChange: trendData['subscriptionsWeekly'] ?? 0.0,
        subscriptionsMonthlyChange: trendData['subscriptionsMonthly'] ?? 0.0,
        subscriptionsSemesterChange: trendData['subscriptionsSemester'] ?? 0.0,
        semesterAnalytics: semesterAnalytics,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] fetchAnalytics error: $e');
      }
      rethrow;
    }
  }

  /// Get total number of unique students
  Future<int> _fetchTotalStudents() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchTotalStudents error: $e');
      }
      return 0;
    }
  }

  /// Get subscription statistics
  Future<Map<String, dynamic>> _fetchSubscriptionStats() async {
    try {
      final snapshot = await _db.collection('subscriptions').get();

      int total = snapshot.docs.length;
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      int expired = 0;

      Map<String, int> bySemester = {};
      Map<String, int> byStatus = {};
      Map<int, int> byYear = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;

        // Handle both old and new format
        String? semester;
        int? year;

        if (data['semester'] is Map) {
          // New format: semester is embedded object
          final semesterData = data['semester'] as Map<String, dynamic>;
          semester = semesterData['semester'] as String?;
          year = semesterData['year'] as int?;
        } else if (data['semester'] is String) {
          // Legacy format: semester is string
          semester = data['semester'] as String?;
          year = data['year'] as int?;
        }

        // Count by status
        if (status != null) {
          byStatus[status] = (byStatus[status] ?? 0) + 1;

          switch (status.toLowerCase()) {
            case 'pending':
              pending++;
              break;
            case 'approved':
              approved++;
              break;
            case 'rejected':
              rejected++;
              break;
            case 'expired':
              expired++;
              break;
          }
        }

        // Count by semester
        if (semester != null) {
          bySemester[semester] = (bySemester[semester] ?? 0) + 1;
        }

        // Count by year
        if (year != null) {
          byYear[year] = (byYear[year] ?? 0) + 1;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'expired': expired,
        'bySemester': bySemester,
        'byStatus': byStatus,
        'byYear': byYear,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchSubscriptionStats error: $e');
      }
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'expired': 0,
        'bySemester': <String, int>{},
        'byStatus': <String, int>{},
        'byYear': <int, int>{},
      };
    }
  }

  /// Get total number of semesters
  Future<int> _fetchTotalSemesters() async {
    try {
      final snapshot = await _db.collection('semesters').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchTotalSemesters error: $e');
      }
      return 0;
    }
  }

  /// Get total number of bus stops
  Future<int> _fetchTotalBusStops() async {
    try {
      final snapshot = await _db.collection('stops').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchTotalBusStops error: $e');
      }
      return 0;
    }
  }

  /// Get recent subscriptions (last 10)
  Future<List<Map<String, dynamic>>> _fetchRecentSubscriptions() async {
    try {
      final snapshot = await _db
          .collection('subscriptions')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchRecentSubscriptions error: $e');
      }
      return [];
    }
  }

  /// Get most popular bus stops
  Future<List<Map<String, dynamic>>> _fetchTopBusStops() async {
    try {
      final snapshot = await _db.collection('subscriptions').get();

      Map<String, int> stopCounts = {};
      Map<String, String> stopNames = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final stop = data['stop'] as Map<String, dynamic>?;

        if (stop != null) {
          final stopId = stop['stopId'] as String?;
          final stopName = stop['stopName'] as String?;

          if (stopId != null && stopName != null) {
            stopCounts[stopId] = (stopCounts[stopId] ?? 0) + 1;
            stopNames[stopId] = stopName;
          }
        }
      }

      // Sort by count and take top 5
      final sortedStops = stopCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedStops
          .take(5)
          .map(
            (entry) => {
              'id': entry.key,
              'name': stopNames[entry.key] ?? 'Unknown',
              'count': entry.value,
            },
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchTopBusStops error: $e');
      }
      return [];
    }
  }

  /// Stream analytics data for real-time updates
  Stream<AnalyticsData> streamAnalytics() {
    return Stream.periodic(
      const Duration(seconds: 30),
      (_) {},
    ).asyncMap((_) => fetchAnalytics()).handleError((error) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] streamAnalytics error: $error');
      }
      return AnalyticsData.empty();
    });
  }

  /// Fetch trend data (weekly, monthly, semester changes)
  Future<Map<String, double>> _fetchTrendData() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));
      final semesterAgo = now.subtract(const Duration(days: 120)); // ~4 months

      // Fetch students trend
      final studentsSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      int studentsWeekAgo = 0;
      int studentsMonthAgo = 0;
      int studentsSemesterAgo = 0;
      int totalStudents = studentsSnapshot.docs.length;

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        DateTime? date;

        if (createdAt != null) {
          if (createdAt is Timestamp) {
            date = createdAt.toDate();
          } else if (createdAt is String) {
            date = DateTime.tryParse(createdAt);
          }
        }

        if (date != null) {
          if (date.isBefore(weekAgo)) studentsWeekAgo++;
          if (date.isBefore(monthAgo)) studentsMonthAgo++;
          if (date.isBefore(semesterAgo)) studentsSemesterAgo++;
        }
      }

      // Fetch subscriptions trend
      final subscriptionsSnapshot = await _db.collection('subscriptions').get();

      int subsWeekAgo = 0;
      int subsMonthAgo = 0;
      int subsSemesterAgo = 0;
      int totalSubs = subscriptionsSnapshot.docs.length;

      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'];
        DateTime? date;

        if (createdAt != null) {
          if (createdAt is Timestamp) {
            date = createdAt.toDate();
          } else if (createdAt is String) {
            date = DateTime.tryParse(createdAt);
          }
        }

        if (date != null) {
          if (date.isBefore(weekAgo)) subsWeekAgo++;
          if (date.isBefore(monthAgo)) subsMonthAgo++;
          if (date.isBefore(semesterAgo)) subsSemesterAgo++;
        }
      }

      // Calculate percentage changes
      final studentsWeeklyChange = studentsWeekAgo > 0
          ? ((totalStudents - studentsWeekAgo) / studentsWeekAgo) * 100
          : 0.0;
      final studentsMonthlyChange = studentsMonthAgo > 0
          ? ((totalStudents - studentsMonthAgo) / studentsMonthAgo) * 100
          : 0.0;
      final studentsSemesterChange = studentsSemesterAgo > 0
          ? ((totalStudents - studentsSemesterAgo) / studentsSemesterAgo) * 100
          : 0.0;

      final subsWeeklyChange = subsWeekAgo > 0
          ? ((totalSubs - subsWeekAgo) / subsWeekAgo) * 100
          : 0.0;
      final subsMonthlyChange = subsMonthAgo > 0
          ? ((totalSubs - subsMonthAgo) / subsMonthAgo) * 100
          : 0.0;
      final subsSemesterChange = subsSemesterAgo > 0
          ? ((totalSubs - subsSemesterAgo) / subsSemesterAgo) * 100
          : 0.0;

      return {
        'studentsWeekly': studentsWeeklyChange,
        'studentsMonthly': studentsMonthlyChange,
        'studentsSemester': studentsSemesterChange,
        'subscriptionsWeekly': subsWeeklyChange,
        'subscriptionsMonthly': subsMonthlyChange,
        'subscriptionsSemester': subsSemesterChange,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchTrendData error: $e');
      }
      return {
        'studentsWeekly': 0.0,
        'studentsMonthly': 0.0,
        'studentsSemester': 0.0,
        'subscriptionsWeekly': 0.0,
        'subscriptionsMonthly': 0.0,
        'subscriptionsSemester': 0.0,
      };
    }
  }

  /// Fetch semester analytics for current year
  Future<Map<String, Map<String, dynamic>>> _fetchSemesterAnalytics() async {
    try {
      final now = DateTime.now();
      final currentYear = now.year;

      // Fetch semester configurations to get actual date ranges
      final semesterConfigsSnapshot = await _db.collection('semesters').get();

      // Find semesters that are active or relevant to current period
      // This includes semesters that span across years (e.g., Fall 2025 - Feb 2026)
      final relevantSemesters = <String, Map<String, dynamic>>{};

      for (var doc in semesterConfigsSnapshot.docs) {
        final data = doc.data();
        final semesterName = data['semester'] as String?;
        final year = data['year'] as int?;
        final startDate = _parseDateTime(data['startDate']);
        final endDate = _parseDateTime(data['endDate']);

        if (semesterName != null && year != null) {
          // Include semester if:
          // 1. It's currently active (now is between start and end)
          // 2. It belongs to current year
          // 3. It spans into current year (even if it started in previous year)
          // 4. It starts in current year (even if it ends in next year)
          final isActive = !now.isBefore(startDate) && !now.isAfter(endDate);
          final belongsToCurrentYear = year == currentYear;
          final spansIntoCurrentYear =
              startDate.year < currentYear && endDate.year >= currentYear;
          final startsInCurrentYear = startDate.year == currentYear;

          if (isActive ||
              belongsToCurrentYear ||
              spansIntoCurrentYear ||
              startsInCurrentYear) {
            final key = '${semesterName}_$year';
            relevantSemesters[key] = {
              'semester': semesterName,
              'year': year,
              'startDate': startDate,
              'endDate': endDate,
            };
          }
        }
      }

      // Fetch all subscriptions
      final subscriptionsSnapshot = await _db.collection('subscriptions').get();

      Map<String, Map<String, dynamic>> analytics = {};

      for (var doc in subscriptionsSnapshot.docs) {
        final data = doc.data();

        // Handle both old and new format
        String? semester;
        int? year;

        if (data['semester'] is Map) {
          // New format: semester is embedded object
          final semesterData = data['semester'] as Map<String, dynamic>;
          semester = semesterData['semester'] as String?;
          year = semesterData['year'] as int?;
        } else if (data['semester'] is String) {
          // Legacy format: semester is string
          semester = data['semester'] as String?;
          year = data['year'] as int?;
        } else if (data['semesterId'] is String) {
          // Very old format: semesterId only
          final parts = (data['semesterId'] as String).split('_');
          if (parts.length == 2) {
            semester = parts[0];
            year = int.tryParse(parts[1]);
          }
        }

        final status = data['status'] as String?;

        if (semester != null && year != null) {
          final key = '${semester}_$year';

          // Only include if this semester is in our relevant list
          if (relevantSemesters.containsKey(key)) {
            if (!analytics.containsKey(semester)) {
              analytics[semester] = {
                'total': 0,
                'pending': 0,
                'approved': 0,
                'rejected': 0,
                'expired': 0,
                'year': year,
                'startDate': relevantSemesters[key]!['startDate'],
                'endDate': relevantSemesters[key]!['endDate'],
              };
            }

            analytics[semester]!['total'] =
                (analytics[semester]!['total'] as int) + 1;

            if (status != null) {
              final statusKey = status.toLowerCase();
              if (analytics[semester]!.containsKey(statusKey)) {
                analytics[semester]![statusKey] =
                    (analytics[semester]![statusKey] as int) + 1;
              }
            }
          }
        }
      }

      return analytics;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] _fetchSemesterAnalytics error: $e');
      }
      return {};
    }
  }

  /// Helper method to parse DateTime from Firestore Timestamp or String
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Cannot parse DateTime from type ${value.runtimeType}');
  }
}
