import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stephenscalender2024/calender/calender_page.dart';

/// How broadly an event should surface in the feed.
/// - [college]: only shown under that one college's filter.
/// - [duWide]: a DU-wide event (fest, inter-college meet, etc.) that
///   should appear regardless of which college filter a student has
///   selected. Still tagged with the organizing [EventsBundle.college]
///   for attribution and moderation.
enum EventVisibility { college, duWide }

EventVisibility _parseVisibility(dynamic raw) {
  if (raw is String && raw.trim().toLowerCase() == 'du_wide') {
    return EventVisibility.duWide;
  }
  return EventVisibility.college;
}

class EventsBundle {
  final String? id;
  final String? title;
  final String? description;
  final String? imageSrc;
  final String? society;
  final String? college;
  final EventVisibility visibility;
  final String? location;
  final String? subtitle;
  final String? tag1;
  final String? tag2;
  final String? reglink;
  final DateTime? registrationDeadline;
  final String? createdByEmail;
  final Color? color;
  final DateTime? startTime;

  EventsBundle({
    this.id,
    this.society,
    this.college,
    this.visibility = EventVisibility.college,
    this.title,
    this.description,
    this.imageSrc,
    this.color,
    this.startTime,
    this.location,
    this.subtitle,
    this.tag1,
    this.tag2,
    this.reglink,
    this.registrationDeadline,
    this.createdByEmail,
  });

  factory EventsBundle.fromFirestoreDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return EventsBundle.fromMap(
      doc.data(),
      doc.id,
      EventsBundleService._getNextColor(),
    );
  }

  factory EventsBundle.fromMap(
    Map<String, dynamic> data,
    String id,
    Color color,
  ) {
    final eventStart =
        _parseDate(data['datetime']) ?? _parseDate(data['startTime']);
    final registration = _parseDate(data['registrationDeadline']);

    return EventsBundle(
      id: id,
      title: _readString(data, ['title', 'eventName']),
      subtitle: _readString(data, ['subtitle', 'category', 'eventType']),
      description: _readString(data, ['description', 'details']),
      imageSrc: _readString(data, ['imageUrl', 'posterUrl']),
      society: _readString(data, ['society', 'societyName']),
      // Old-format events (pre-multi-college) have no `college` field at
      // all; treat those as the app's original home college so existing
      // data keeps showing up under that filter instead of disappearing.
      college: _readString(data, ['college']).isNotEmpty
          ? _readString(data, ['college'])
          : "St. Stephen's College",
      visibility: _parseVisibility(data['visibility']),
      location: _readString(data, ['location']),
      tag1: _readString(data, ['tag1']),
      tag2: _readString(data, ['tag2']),
      reglink: _readString(data, ['reglink', 'registrationForm']),
      registrationDeadline: registration,
      startTime: eventStart,
      createdByEmail: _readString(data, ['email', 'createdBy']),
      color: color,
    );
  }

  static String _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return '';
  }

  static DateTime? _parseDate(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }
    if (rawValue is Timestamp) {
      return rawValue.toDate();
    }
    if (rawValue is DateTime) {
      return rawValue;
    }
    if (rawValue is String) {
      return DateTime.tryParse(rawValue);
    }
    return null;
  }
}

class EventsBundleService {
  static Query<Map<String, dynamic>> _upcomingEventsQuery() {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 5)),
    );

    return FirebaseFirestore.instance
        .collection('events')
        .where('datetime', isGreaterThanOrEqualTo: cutoff)
        .orderBy('datetime');
  }

  static Future<List<EventsBundle?>> fetchEventsFromFirestore(
      EventBundlesProvider eventBundlesProvider) async {
    try {
      final snapshot = await _upcomingEventsQuery().get();

      final eventBundles = _toUpcomingEvents(snapshot.docs);
      eventBundlesProvider.setEventBundles(eventBundles.cast<EventsBundle?>());

      return eventBundles.cast<EventsBundle?>();
    } catch (e) {
      print("Error fetching events: $e");
      return [];
    }
  }

  static Stream<List<EventsBundle>> streamUpcomingEvents({
    EventBundlesProvider? provider,
  }) {
    return _upcomingEventsQuery().snapshots().map((snapshot) {
      final upcoming = _toUpcomingEvents(snapshot.docs);
      if (provider != null) {
        provider.setEventBundles(upcoming.cast<EventsBundle?>());
      }
      return upcoming;
    });
  }

  static List<EventsBundle> _toUpcomingEvents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now();
    final List<EventsBundle> result = [];

    for (final doc in docs) {
      try {
        final event = EventsBundle.fromFirestoreDoc(doc);
        if (event.startTime != null && event.startTime!.isAfter(now)) {
          result.add(event);
        }
      } catch (e) {
        print('Skipping malformed event ${doc.id}: $e');
      }
    }

    result.sort((a, b) => (a.startTime ?? now).compareTo(b.startTime ?? now));
    return result;
  }

  static List<Color> predefinedColors = [
    Color(0xFF535878),
    Color(0xFF9DB0CE),
    Color(0xFF1D1A39),
    Color(0xFF451952),
    Color(0xFFAE445A),
    Color(0xFF62A58F),
    Color(0xFFE78686),
    Color(0xFF8354A0),
    Color(0xFF5696A2),
    Color(0xFFE9C46A),
    Color(0xFF5E8A7A),
  ];

  static int _currentColorIndex = 0;

  static Color _getNextColor() {
    if (_currentColorIndex >= predefinedColors.length) {
      _currentColorIndex = 0; // Loop back to the beginning
    }
    final color = predefinedColors[_currentColorIndex];
    _currentColorIndex++;
    return color;
  }
}
