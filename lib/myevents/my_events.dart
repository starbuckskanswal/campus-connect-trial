import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditEventPage extends StatefulWidget {
  const EditEventPage({super.key});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting event. Please try again.')),
      );
    }
  }

  Future<void> editEvent({
    required String eventId,
    required String title,
    required String subtitle,
    required String description,
    required String location,
    required String reglink,
    required Timestamp datetime,
    required Timestamp? registrationDeadline,
  }) async {
    final titleController = TextEditingController(text: title);
    final subtitleController = TextEditingController(text: subtitle);
    final descriptionController = TextEditingController(text: description);
    final locationController = TextEditingController(text: location);
    final regLinkController = TextEditingController(text: reglink);

    DateTime selectedEventDateTime = datetime.toDate();
    DateTime selectedRegistrationDeadline = registrationDeadline?.toDate() ?? datetime.toDate();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: subtitleController,
                      decoration: const InputDecoration(labelText: 'Subtitle'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    TextField(
                      controller: regLinkController,
                      decoration: const InputDecoration(labelText: 'Registration Link'),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event),
                      title: const Text('Event Date & Time'),
                      subtitle: Text(DateFormat('d MMM yyyy, hh:mm a').format(selectedEventDateTime)),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedEventDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate == null || !mounted) {
                          return;
                        }

                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedEventDateTime),
                        );
                        if (pickedTime == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedEventDateTime = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Registration Deadline'),
                      subtitle: Text(DateFormat('d MMM yyyy, hh:mm a').format(selectedRegistrationDeadline)),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedRegistrationDeadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate == null || !mounted) {
                          return;
                        }

                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedRegistrationDeadline),
                        );
                        if (pickedTime == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedRegistrationDeadline = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await updateEvent(
                      eventId: eventId,
                      title: titleController.text,
                      subtitle: subtitleController.text,
                      description: descriptionController.text,
                      location: locationController.text,
                      reglink: regLinkController.text,
                      eventDateTime: selectedEventDateTime,
                      registrationDeadline: selectedRegistrationDeadline,
                    );
                    if (!mounted) {
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String subtitle,
    required String description,
    required String location,
    required String reglink,
    required DateTime eventDateTime,
    required DateTime registrationDeadline,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(eventId).update({
        'title': title,
        'subtitle': subtitle,
        'description': description,
        'location': location,
        'reglink': reglink,
        'datetime': Timestamp.fromDate(eventDateTime),
        'registrationDeadline': Timestamp.fromDate(registrationDeadline),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating event. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to manage events.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage My Events')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('email', isEqualTo: (user.email ?? '').trim().toLowerCase())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          docs.sort((a, b) {
            final aTs = a.data()['datetime'];
            final bTs = b.data()['datetime'];
            final aDate = aTs is Timestamp ? aTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = bTs is Timestamp ? bTs.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
            return aDate.compareTo(bDate);
          });
          if (docs.isEmpty) {
            return const Center(child: Text('No events found for your account.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final event = docs[index];
              final data = event.data();

              final title = (data['title'] ?? '').toString();
              final subtitle = (data['subtitle'] ?? '').toString();
              final description = (data['description'] ?? '').toString();
              final location = (data['location'] ?? '').toString();
              final reglink = (data['reglink'] ?? '').toString();
              final eventDate = data['datetime'] as Timestamp?;
              final regDeadline = data['registrationDeadline'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: ListTile(
                  title: Text(title.isNotEmpty ? title : 'Untitled Event'),
                  subtitle: Text(
                    '${subtitle.isNotEmpty ? '$subtitle\n' : ''}${eventDate != null ? DateFormat('d MMM yyyy, hh:mm a').format(eventDate.toDate()) : 'Date TBA'}',
                  ),
                  isThreeLine: subtitle.isNotEmpty,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: eventDate == null
                            ? null
                            : () {
                                editEvent(
                                  eventId: event.id,
                                  title: title,
                                  subtitle: subtitle,
                                  description: description,
                                  location: location,
                                  reglink: reglink,
                                  datetime: eventDate,
                                  registrationDeadline: regDeadline,
                                );
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text('Are you sure you want to delete this event?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteEvent(event.id);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
