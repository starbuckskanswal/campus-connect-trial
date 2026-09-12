import 'package:flutter/material.dart';
import 'package:stephenscalender2024/eventdetails/events_details.dart';
import 'package:stephenscalender2024/eventshome/components/event_feed_card.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/favoriteservice.dart';

class Bookmarks extends StatefulWidget {
  const Bookmarks({super.key});

  @override
  State<Bookmarks> createState() => _BookmarksState();
}

class _BookmarksState extends State<Bookmarks> {
  late final Stream<List<EventsBundle>> _eventsStream;
  Set<String> _interestedIds = {};
  Set<String> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    _eventsStream = EventsBundleService.streamUpcomingEvents();
    _loadPreferenceSets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Events'),
      ),
      body: StreamBuilder<List<EventsBundle>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? const <EventsBundle>[];
          final saved = events.where((event) {
            final id = event.id;
            return id != null && _interestedIds.contains(id);
          }).toList()
            ..sort((a, b) => (a.startTime ?? DateTime.now()).compareTo(b.startTime ?? DateTime.now()));

          if (saved.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'No saved events yet. Tap "Save" on any event in For You or Explore.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: saved.length,
            itemBuilder: (context, index) {
              final event = saved[index];
              final id = event.id ?? '';

              return EventFeedCard(
                event: event,
                isInterested: _interestedIds.contains(id),
                isDismissed: _dismissedIds.contains(id),
                onInterestedToggle: () => _toggleInterested(event),
                onDismissToggle: () => _toggleDismissed(event),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(eventsBundle: event),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _loadPreferenceSets() async {
    final interested = await FavoritesService.getInterestedIds();
    final dismissed = await FavoritesService.getDismissedIds();

    if (!mounted) {
      return;
    }

    setState(() {
      _interestedIds = interested;
      _dismissedIds = dismissed;
    });
  }

  Future<void> _toggleInterested(EventsBundle event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }
    final next = !_interestedIds.contains(id);
    await FavoritesService.setInterested(id, next);
    await _loadPreferenceSets();
  }

  Future<void> _toggleDismissed(EventsBundle event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }
    final next = !_dismissedIds.contains(id);
    await FavoritesService.setDismissed(id, next);
    await _loadPreferenceSets();
  }
}
