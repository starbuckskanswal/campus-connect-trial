import 'package:flutter/material.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/eventdetails/components/body.dart';
class EventDetailsPage extends StatelessWidget {
  final EventsBundle eventsBundle;
  const EventDetailsPage({super.key, required this.eventsBundle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Body(eventsBundle: eventsBundle,),
    );
  }
}
