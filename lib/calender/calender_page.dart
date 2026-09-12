import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/myevents/screens/addevent.dart';
import 'package:table_calendar/table_calendar.dart';

class EventBundlesProvider extends ChangeNotifier {
  List<EventsBundle?> _eventBundles = [];

  List<EventsBundle?> get eventBundles => _eventBundles;

  void setEventBundles(List<EventsBundle?> bundles) {
    _eventBundles = bundles;
    notifyListeners();
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  late CalendarFormat _calendarFormat;
  List<EventsBundle?> _selectedEvents = [];
  late Map<DateTime, List<EventsBundle?>> _events;
  late Map<DateTime, List<EventsBundle?>> _eventsByDate;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _calendarFormat = CalendarFormat.month;
    _firstDay = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _lastDay = DateTime(2030, 12, 31);
    _events = {};
    _eventsByDate = {};
    _populateEvents();
  }

  void _populateEvents() {
    final eventBundlesProvider = Provider.of<EventBundlesProvider>(context, listen: false);
    final eventBundles = eventBundlesProvider.eventBundles;

    _events.clear();

    for (var event in eventBundles) {
      final startTime = event!.startTime!;
      final date = DateTime(startTime.year, startTime.month, startTime.day);
      _events[date] = _events[date] ?? [];
      _events[date]!.add(event);
    }

    setState(() {
      _eventsByDate = _groupEventsByDate(eventBundles);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEvent()),
                );
              },
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: TableCalendar(
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  eventLoader: (day) {
                    return _eventsByDate[day] ?? [];
                  },
                  calendarFormat: _calendarFormat,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      DateTime newDate = DateTime(date.year, date.month, date.day);
                      final hasEvents = _eventsByDate[newDate] != null && _eventsByDate[newDate]!.isNotEmpty;
                      if (hasEvents) {
                        return Positioned(
                          bottom: 2,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                            ),
                            width: 5,
                            height: 5,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },

                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                      _focusedDay = focusedDay;
                      _selectedEvents = _eventsByDate[_selectedDay] ?? [];
                    });
                  },
                  availableGestures: AvailableGestures.horizontalSwipe,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                      // _firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
                      // _lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
                    });
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          if (_selectedEvents.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _selectedEvents.length,
                itemBuilder: (context, index) {
                  EventsBundle? event = _selectedEvents[index];
                  return Container(
                    color: event!.color,
                    child: ListTile(
                      title: Text(
                        event.title!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        event.description!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        DateFormat.Hm().format(event.startTime!).toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Map<DateTime, List<EventsBundle?>> _groupEventsByDate(List<EventsBundle?> events) {
    Map<DateTime, List<EventsBundle?>> groupedEvents = {};
    for (var event in events) {
      final startTime = event!.startTime!;
      final date = DateTime(startTime.year, startTime.month, startTime.day);
      groupedEvents[date] = groupedEvents[date] ?? [];
      groupedEvents[date]!.add(event);
    }
    return groupedEvents;
  }
}
