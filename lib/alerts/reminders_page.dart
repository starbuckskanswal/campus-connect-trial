import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stephenscalender2024/eventdetails/events_details.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/favoriteservice.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late final Stream<List<EventsBundle>> _eventsStream;
  Set<String> _interestedIds = {};

  @override
  void initState() {
    super.initState();
    _eventsStream = EventsBundleService.streamUpcomingEvents();
    _loadInterestedIds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Timeline')),
      body: StreamBuilder<List<EventsBundle>>(
        stream: _eventsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final now = DateTime.now();
          final events = (snapshot.data ?? const <EventsBundle>[]).where((event) {
            final id = event.id;
            return id != null && _interestedIds.contains(id);
          }).toList()
            ..sort((a, b) => (a.startTime ?? now).compareTo(b.startTime ?? now));

          if (events.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  'No reminders yet. Save events with the \"Interested\" button to track them here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final start = event.startTime ?? now;
              final distance = start.difference(now);
              final reminderLabel = _humanize(distance);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  title: Text(event.title?.isNotEmpty == true ? event.title! : 'Untitled Event'),
                  subtitle: Text(
                    '${DateFormat('EEE, d MMM • hh:mm a').format(start)}\n$reminderLabel',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsPage(eventsBundle: event),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _humanize(Duration delta) {
    if (delta.inMinutes <= 60) {
      return 'Starts in ${delta.inMinutes} min';
    }
    if (delta.inHours < 24) {
      return 'Starts in ${delta.inHours} hour(s)';
    }
    return 'Starts in ${delta.inDays} day(s)';
  }

  Future<void> _loadInterestedIds() async {
    final ids = await FavoritesService.getInterestedIds();
    if (!mounted) {
      return;
    }
    setState(() {
      _interestedIds = ids;
    });
  }
}
