import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stephenscalender2024/eventdetails/components/body.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';

void main() {
  EventsBundle buildEvent({String? poster}) {
    return EventsBundle(
      id: 'test-event',
      title: 'Tech Fest 2026',
      subtitle: 'Annual technology festival',
      description: 'A full day of talks and demos.',
      imageSrc: poster,
      society: 'Tech Society',
      location: 'Main Auditorium',
      startTime: DateTime(2026, 9, 1, 10, 0),
      registrationDeadline: DateTime(2026, 8, 30, 18, 0),
    );
  }

  testWidgets('poster area uses full Instagram 4:5 aspect ratio',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Body(eventsBundle: buildEvent(poster: 'https://example.com/poster.jpg')),
        ),
      ),
    );

    final aspectRatioFinder = find.byType(AspectRatio);
    expect(aspectRatioFinder, findsOneWidget);

    final aspectRatio = tester.widget<AspectRatio>(aspectRatioFinder);
    expect(aspectRatio.aspectRatio, closeTo(4 / 5, 0.0001));

    // The rendered poster box must actually be 4:5 on screen.
    final size = tester.getSize(aspectRatioFinder);
    expect(size.width / size.height, closeTo(4 / 5, 0.01));

    // Fullscreen affordance is present.
    expect(find.byIcon(Icons.fullscreen), findsOneWidget);
  });

  testWidgets('events without a poster show the fallback, no fullscreen button',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Body(eventsBundle: buildEvent(poster: null))),
      ),
    );

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byIcon(Icons.fullscreen), findsNothing);
  });
}
