import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stephenscalender2024/accessibility/color_mode_controller.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';

void main() {
  test('parses the current event schema', () {
    final start = Timestamp.fromDate(DateTime(2026, 4, 15, 18, 30));
    final deadline = Timestamp.fromDate(DateTime(2026, 4, 14, 23, 59));
    const color = Color(0xFF123456);

    final bundle = EventsBundle.fromMap({
      'title': 'Founders Meetup',
      'subtitle': 'Pitch, network, build',
      'description': 'Meet the startup community on campus.',
      'imageUrl': 'https://example.com/poster.jpg',
      'society': 'Entrepreneurship Cell',
      'location': 'Auditorium',
      'reglink': 'https://forms.example.com/founders',
      'registrationDeadline': deadline,
      'datetime': start,
      'createdBy': 'ecell@college.edu',
    }, 'event-001', color);

    expect(bundle.id, 'event-001');
    expect(bundle.title, 'Founders Meetup');
    expect(bundle.subtitle, 'Pitch, network, build');
    expect(bundle.description, 'Meet the startup community on campus.');
    expect(bundle.imageSrc, 'https://example.com/poster.jpg');
    expect(bundle.society, 'Entrepreneurship Cell');
    expect(bundle.location, 'Auditorium');
    expect(bundle.reglink, 'https://forms.example.com/founders');
    expect(bundle.startTime, start.toDate());
    expect(bundle.registrationDeadline, deadline.toDate());
    expect(bundle.createdByEmail, 'ecell@college.edu');
    expect(bundle.color, color);
  });

  test('falls back to legacy event field names', () {
    final bundle = EventsBundle.fromMap({
      'eventName': 'Quiz Night',
      'category': 'Competition',
      'details': 'Inter-society trivia finals.',
      'posterUrl': 'https://example.com/quiz.jpg',
      'societyName': 'Quiz Club',
      'registrationForm': 'quiz.example.com',
      'startTime': '2026-04-20T17:00:00.000',
      'email': 'quizclub@college.edu',
    }, 'legacy-001', const Color(0xFF654321));

    expect(bundle.title, 'Quiz Night');
    expect(bundle.subtitle, 'Competition');
    expect(bundle.description, 'Inter-society trivia finals.');
    expect(bundle.imageSrc, 'https://example.com/quiz.jpg');
    expect(bundle.society, 'Quiz Club');
    expect(bundle.reglink, 'quiz.example.com');
    expect(bundle.createdByEmail, 'quizclub@college.edu');
    expect(bundle.startTime, DateTime.parse('2026-04-20T17:00:00.000'));
  });

  test('loads and stores the preferred app color mode', () async {
    SharedPreferences.setMockInitialValues({
      'appColorMode': AppColorMode.darkHighContrast.storageValue,
    });

    final controller = ColorModeController();
    await controller.load();

    expect(controller.mode, AppColorMode.darkHighContrast);
    expect(controller.usesHighContrast, isTrue);

    await controller.setMode(AppColorMode.highContrast);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('appColorMode'),
      AppColorMode.highContrast.storageValue,
    );
  });
}
