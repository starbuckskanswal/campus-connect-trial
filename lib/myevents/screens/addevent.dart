import 'package:flutter/material.dart';
import 'package:stephenscalender2024/myevents/components/addevent_body.dart';

class AddEvent extends StatelessWidget {
  const AddEvent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Event")
      ),
      body: const AddEventBody(),
    );
  }
}
