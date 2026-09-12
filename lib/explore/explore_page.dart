import 'package:flutter/material.dart';
import 'package:stephenscalender2024/eventdetails/events_details.dart';
import 'package:stephenscalender2024/eventshome/components/event_feed_card.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/favoriteservice.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final Stream<List<EventsBundle>> _eventsStream;
  final TextEditingController _searchController = TextEditingController();

  Set<String> _interestedIds = {};
  Set<String> _dismissedIds = {};

  String _selectedSociety = 'All';
  bool _showHidden = false;

  @override
  void initState() {
    super.initState();
    _eventsStream = EventsBundleService.streamUpcomingEvents();
    _loadPreferenceSets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Events')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, society, place',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventsBundle>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load events: ${snapshot.error}'));
                }

                final events = snapshot.data ?? const <EventsBundle>[];
                final societies = _extractSocieties(events);
                final filtered = _filter(events);

                return Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _societyChip('All'),
                          for (final society in societies) _societyChip(society),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text('Show hidden'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showHidden,
                            onChanged: (value) {
                              setState(() {
                                _showHidden = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching events'))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final event = filtered[index];
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
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _societyChip(String label) {
    final selected = _selectedSociety == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) {
          setState(() {
            _selectedSociety = label;
          });
        },
      ),
    );
  }

  List<EventsBundle> _filter(List<EventsBundle> input) {
    final query = _searchController.text.trim().toLowerCase();

    return input.where((event) {
      final id = event.id ?? '';
      if (!_showHidden && id.isNotEmpty && _dismissedIds.contains(id)) {
        return false;
      }
      if (_selectedSociety != 'All' && (event.society ?? '') != _selectedSociety) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchable = <String>[
        event.title ?? '',
        event.subtitle ?? '',
        event.description ?? '',
        event.society ?? '',
        event.location ?? '',
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList()
      ..sort((a, b) => (a.startTime ?? DateTime.now()).compareTo(b.startTime ?? DateTime.now()));
  }

  List<String> _extractSocieties(List<EventsBundle> events) {
    return events
        .map((event) => (event.society ?? '').trim())
        .where((society) => society.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
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
