import 'package:flutter/material.dart';
import 'package:stephenscalender2024/constants.dart';
import 'package:stephenscalender2024/eventdetails/events_details.dart';
import 'package:stephenscalender2024/eventshome/components/event_feed_card.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/favoriteservice.dart';

class NoticeboardPage extends StatefulWidget {
  const NoticeboardPage({super.key});

  @override
  State<NoticeboardPage> createState() => _NoticeboardPageState();
}

class _NoticeboardPageState extends State<NoticeboardPage> {
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
    final adminEmail = kNoticeboardAdminEmail.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Noticeboard')),
      body: adminEmail.isEmpty || adminEmail == 'collegeadmin@example.com'
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Set the real college admin email in lib/constants.dart to enable the noticeboard feed.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<EventsBundle>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load noticeboard updates: ${snapshot.error}'));
                }

                final updates = (snapshot.data ?? const <EventsBundle>[])
                    .where((event) => (event.createdByEmail ?? '').trim().toLowerCase() == adminEmail)
                    .toList()
                  ..sort((a, b) => (b.startTime ?? DateTime.now()).compareTo(a.startTime ?? DateTime.now()));

                if (updates.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'No noticeboard posts from the college admin yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: updates.length,
                  itemBuilder: (context, index) {
                    final event = updates[index];
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
