import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stephenscalender2024/calender/calender_page.dart';
import 'package:stephenscalender2024/eventdetails/events_details.dart';
import 'package:stephenscalender2024/eventshome/components/event_feed_card.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/favoriteservice.dart';

class Body extends StatefulWidget {
  final String searchKeyword;

  const Body({super.key, required this.searchKeyword});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  late final Stream<List<EventsBundle>> _eventsStream;

  Set<String> _interestedIds = {};
  Set<String> _dismissedIds = {};
  Set<String> _preferredSocieties = {};

  String _selectedSociety = 'All';
  bool _showHidden = false;
  bool _isPreferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EventBundlesProvider>(context, listen: false);
    _eventsStream =
        EventsBundleService.streamUpcomingEvents(provider: provider);
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For You',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track what matters and hide noise from your feed.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showInterestsSheet(context);
                  },
                  icon: const Icon(Icons.tune),
                  tooltip: 'Set interests',
                ),
              ],
            ),
          ),
          if (!_isPreferencesLoaded)
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          Expanded(
            child: StreamBuilder<List<EventsBundle>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading events: ${snapshot.error}'));
                }

                final events = snapshot.data ?? const <EventsBundle>[];
                final societies = _extractSocieties(events);
                final filtered = _filterAndRankEvents(events);

                return Column(
                  children: [
                    SizedBox(
                      height: 46,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        children: [
                          const SizedBox(width: 4),
                          _societyChip('All'),
                          for (final society in societies)
                            _societyChip(society),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Switch(
                            value: _showHidden,
                            onChanged: (value) {
                              setState(() {
                                _showHidden = value;
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          const Text('Show hidden events'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'No events match your current feed settings yet.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final event = filtered[index];
                                final id = event.id ?? '';
                                final isInterested =
                                    _interestedIds.contains(id);
                                final isDismissed = _dismissedIds.contains(id);

                                return EventFeedCard(
                                  event: event,
                                  isInterested: isInterested,
                                  isDismissed: isDismissed,
                                  onInterestedToggle: () =>
                                      _toggleInterested(event),
                                  onDismissToggle: () =>
                                      _toggleDismissed(event),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventDetailsPage(
                                            eventsBundle: event),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

  List<EventsBundle> _filterAndRankEvents(List<EventsBundle> events) {
    final keyword = widget.searchKeyword.trim().toLowerCase();
    final now = DateTime.now();

    final filtered = events.where((event) {
      final id = event.id ?? '';
      if (!_showHidden && id.isNotEmpty && _dismissedIds.contains(id)) {
        return false;
      }

      if (_selectedSociety != 'All' &&
          (event.society ?? '') != _selectedSociety) {
        return false;
      }

      if (keyword.isNotEmpty) {
        final combined = <String>[
          event.title ?? '',
          event.subtitle ?? '',
          event.description ?? '',
          event.society ?? '',
          event.location ?? '',
        ].join(' ').toLowerCase();

        if (!combined.contains(keyword)) {
          return false;
        }
      }

      return (event.startTime ?? now)
          .isAfter(now.subtract(const Duration(minutes: 5)));
    }).toList();

    filtered.sort((a, b) {
      final aScore = _scoreEvent(a, now);
      final bScore = _scoreEvent(b, now);

      if (aScore != bScore) {
        return bScore.compareTo(aScore);
      }
      return (a.startTime ?? now).compareTo(b.startTime ?? now);
    });

    return filtered;
  }

  int _scoreEvent(EventsBundle event, DateTime now) {
    var score = 0;
    final id = event.id ?? '';
    final society = event.society ?? '';
    final start = event.startTime;
    final deadline = event.registrationDeadline;

    if (id.isNotEmpty && _interestedIds.contains(id)) {
      score += 8;
    }

    if (society.isNotEmpty && _preferredSocieties.contains(society)) {
      score += 4;
    }

    if (deadline != null) {
      final hoursUntilDeadline = deadline.difference(now).inHours;
      if (hoursUntilDeadline > 0 && hoursUntilDeadline <= 48) {
        score += 3;
      }
    }

    if (start != null) {
      final hoursUntilStart = start.difference(now).inHours;
      if (hoursUntilStart <= 24) {
        score += 2;
      } else if (hoursUntilStart <= 72) {
        score += 1;
      }
    }

    return score;
  }

  List<String> _extractSocieties(List<EventsBundle> events) {
    return events
        .map((event) => (event.society ?? '').trim())
        .where((society) => society.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _loadPreferences() async {
    final interestedIds = await FavoritesService.getInterestedIds();
    final dismissedIds = await FavoritesService.getDismissedIds();
    final preferredSocieties = await FavoritesService.getPreferredSocieties();

    if (!context.mounted) {
      return;
    }

    setState(() {
      _interestedIds = interestedIds;
      _dismissedIds = dismissedIds;
      _preferredSocieties = preferredSocieties;
      _isPreferencesLoaded = true;
    });
  }

  Future<void> _toggleInterested(EventsBundle event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }

    final nextValue = !_interestedIds.contains(id);
    await FavoritesService.setInterested(id, nextValue);
    await _loadPreferences();
  }

  Future<void> _toggleDismissed(EventsBundle event) async {
    final id = event.id;
    if (id == null || id.isEmpty) {
      return;
    }

    final nextValue = !_dismissedIds.contains(id);
    await FavoritesService.setDismissed(id, nextValue);
    await _loadPreferences();
  }

  Future<void> _showInterestsSheet(BuildContext context) async {
    final events = await _eventsStream.first;
    final allSocieties = _extractSocieties(events);
    final selected = Set<String>.from(_preferredSocieties);

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose your interests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recommended events will prioritize these societies.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allSocieties.map((society) {
                      final isSelected = selected.contains(society);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(society),
                        onSelected: (value) {
                          setModalState(() {
                            if (value) {
                              selected.add(society);
                            } else {
                              selected.remove(society);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await FavoritesService.setPreferredSocieties(selected);
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop();
                        await _loadPreferences();
                      },
                      child: const Text('Save interests'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
