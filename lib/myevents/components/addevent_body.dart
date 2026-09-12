import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stephenscalender2024/homepage/homepage.dart';
import 'package:stephenscalender2024/login/components/background.dart';
import 'package:stephenscalender2024/login/components/rounded_input_field.dart';
import 'package:stephenscalender2024/services/user_role_service.dart';
import 'package:stephenscalender2024/welcomescreen/components/rounded_button.dart';

class AddEventBody extends StatefulWidget {
  const AddEventBody({super.key});

  @override
  State<AddEventBody> createState() => _AddEventBodyState();
}

class _AddEventBodyState extends State<AddEventBody> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController reglinkController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? selectedSociety;
  DateTime? selectedEventDateTime;
  DateTime? selectedRegistrationDeadline;
  List<String> societyNames = [];

  // The signed-in POC's college, from their own society_admins doc (the
  // same value firestore.rules validates writes against). Not user-typed:
  // a POC can only ever post under the college they're allowlisted for.
  String? _adminCollege;

  // Whether this event should surface DU-wide (fests, inter-college
  // events) rather than only under the organizing college's filter.
  bool _isDuWideEvent = false;

  File? posterImage;
  String imageUrl = '';

  bool _isCreatingEvent = false;
  bool _isUploadingPoster = false;

  @override
  void initState() {
    super.initState();
    loadSocietyNames();
    _loadAdminCollege();
  }

  Future<void> _loadAdminCollege() async {
    final college = await UserRoleService.getCurrentUserCollege();
    if (mounted) {
      setState(() => _adminCollege = college);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    locationController.dispose();
    reglinkController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadSocietyNames() async {
    societyNames = await retrieveSocietyNames();
    if (societyNames.isNotEmpty) {
      selectedSociety = societyNames.first;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<String>> retrieveSocietyNames() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = prefs.getStringList('societies');

    if (listJson == null) {
      return [];
    }

    return listJson
        .map((jsonStr) {
          try {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            return map['name']?.toString() ?? '';
          } catch (_) {
            return '';
          }
        })
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<void> _pickEventDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedEventDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          selectedEventDateTime ?? now.add(const Duration(hours: 1))),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      selectedEventDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickRegistrationDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedRegistrationDeadline ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedRegistrationDeadline ?? now),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      selectedRegistrationDeadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> createEvent() async {
    if (_isCreatingEvent) {
      return;
    }

    setState(() {
      _isCreatingEvent = true;
    });

    try {
      if (selectedSociety == null || selectedSociety!.isEmpty) {
        throw Exception('Please select a society');
      }
      if (selectedEventDateTime == null) {
        throw Exception('Please choose event date and time');
      }
      if (selectedRegistrationDeadline == null) {
        throw Exception('Please choose registration deadline');
      }

      final now = DateTime.now();
      if (selectedEventDateTime!.isBefore(now)) {
        throw Exception('Event date and time must be in the future');
      }
      if (selectedRegistrationDeadline!.isAfter(selectedEventDateTime!)) {
        throw Exception('Registration deadline should be before event start');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final userEmail = (user.email ?? '').trim().toLowerCase();

      final canManage = await UserRoleService.canManageEvents();
      if (!canManage) {
        throw Exception('Only allowlisted society POCs can create events');
      }
      if (_adminCollege == null || _adminCollege!.isEmpty) {
        throw Exception(
            'Your account is not linked to a college yet. Contact an admin to finish onboarding.');
      }

      await FirebaseFirestore.instance.collection('events').add({
        'email': userEmail,
        'createdBy': userEmail,
        'title': titleController.text.trim(),
        'subtitle': subtitleController.text.trim(),
        'society': selectedSociety,
        'college': _adminCollege,
        'visibility': _isDuWideEvent ? 'du_wide' : 'college',
        'location': locationController.text.trim(),
        'datetime': Timestamp.fromDate(selectedEventDateTime!),
        'registrationDeadline':
            Timestamp.fromDate(selectedRegistrationDeadline!),
        'description': descriptionController.text.trim(),
        'reglink': reglinkController.text.trim(),
        'imageUrl': imageUrl,
        'posterUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event published successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingEvent = false;
        });
      }
    }
  }

  Future<void> _pickPosterImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      posterImage = File(pickedFile.path);
      _isUploadingPoster = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please sign in before uploading posters.');
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('poster_images')
          .child(user.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(posterImage!);
      final snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error uploading poster image. Please retry.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPoster = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedInputField(
                  hintText: 'Name of Event',
                  icon: Icons.event,
                  controller: titleController,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter event name'
                      : null,
                ),
                RoundedInputField(
                  hintText: 'One-line summary',
                  icon: Icons.subtitles,
                  controller: subtitleController,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please add a subtitle'
                      : null,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: DropdownButton<String>(
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    value: selectedSociety,
                    hint: const Text('Select Society'),
                    onChanged: (value) {
                      setState(() {
                        selectedSociety = value;
                      });
                    },
                    items: societyNames.map((name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('DU-wide event'),
                    subtitle: Text(
                      _adminCollege == null
                          ? 'Loading your college...'
                          : _isDuWideEvent
                              ? 'Shown to students across DU, not just $_adminCollege'
                              : 'Shown only under $_adminCollege',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isDuWideEvent,
                    onChanged: (value) => setState(() => _isDuWideEvent = value),
                  ),
                ),
                const SizedBox(height: 8),
                RoundedInputField(
                  hintText: 'Location',
                  icon: Icons.location_on,
                  controller: locationController,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please add a location'
                      : null,
                ),
                _dateTimeRow(
                  icon: Icons.calendar_month,
                  label: 'Event Date & Time',
                  value: selectedEventDateTime,
                  onTap: _pickEventDateTime,
                ),
                _dateTimeRow(
                  icon: Icons.timer_outlined,
                  label: 'Registration Deadline',
                  value: selectedRegistrationDeadline,
                  onTap: _pickRegistrationDeadline,
                ),
                RoundedInputField(
                  hintText: 'Registration Form Link',
                  icon: Icons.link,
                  controller: reglinkController,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please add registration link'
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: TextFormField(
                    controller: descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      icon: Icon(Icons.description),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please add event description'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isUploadingPoster ? null : _pickPosterImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(imageUrl.isEmpty
                          ? 'Upload Poster'
                          : 'Poster Uploaded'),
                    ),
                    if (_isUploadingPoster) const CircularProgressIndicator(),
                  ],
                ),
                if (posterImage != null && posterImage!.lengthSync() > 1000000)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Warning: image is larger than 1MB. Consider compressing for better loading speed.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),
                RoundedButton(
                  text: _isCreatingEvent ? 'PUBLISHING...' : 'PUBLISH EVENT',
                  press: () {
                    if (_isCreatingEvent) {
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      createEvent();
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateTimeRow({
    required IconData icon,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final text =
        value == null ? label : DateFormat('d MMM yyyy, hh:mm a').format(value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(29),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: value == null ? Colors.grey.shade700 : Colors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
