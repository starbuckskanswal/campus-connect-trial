import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stephenscalender2024/accessibility/color_mode_controller.dart';
import 'package:stephenscalender2024/eventshome/components/body.dart';
import 'package:stephenscalender2024/welcome_screen.dart';

class EventsHome extends StatefulWidget {
  const EventsHome({super.key});

  @override
  State<EventsHome> createState() => _EventsHomeState();
}

class _EventsHomeState extends State<EventsHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String searchKeyword = '';

  Future<String> getEmailFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: buildAppBar(),
      drawer: buildDrawer(context),
      body: Body(searchKeyword: searchKeyword),
    );
  }

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String>(
        future: getEmailFromPrefs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final email = snapshot.data ?? '';
          final colorModeController = context.watch<ColorModeController>();
          final colors = Theme.of(context).colorScheme;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: colors.primary),
                child: Text(
                  'Campus Connect',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(email.isNotEmpty ? email : 'Signed in user'),
              ),
              ListTile(
                title: const Text('Display options'),
                subtitle: Text(colorModeController.mode.label),
                leading: const Icon(Icons.contrast),
                onTap: () {
                  _showDisplayOptionsSheet(context);
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  final colorModeController =
                      context.read<ColorModeController>();
                  final colorMode = colorModeController.mode;
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  await colorModeController.setMode(colorMode);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WelcomeScreen()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDisplayOptionsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer<ColorModeController>(
            builder: (context, colorModeController, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display options',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a color mode with stronger contrast for easier reading.',
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<AppColorMode>(
                      groupValue: colorModeController.mode,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        colorModeController.setMode(value);
                      },
                      child: Column(
                        children: [
                          for (final mode in AppColorMode.values)
                            RadioListTile<AppColorMode>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(mode.label),
                              subtitle: Text(mode.description),
                              value: mode,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: const Text('Campus Connect'),
      actions: [
        IconButton(
          onPressed: () async {
            final result = await showSearch<String>(
              context: context,
              delegate: EventSearchDelegate(
                initialQuery: searchKeyword,
                onSearch: (query) {
                  setState(() {
                    searchKeyword = query.toLowerCase();
                  });
                },
              ),
            );

            if (result != null) {
              setState(() {
                searchKeyword = result.toLowerCase();
              });
            }
          },
          icon: const Icon(Icons.search),
        ),
      ],
    );
  }
}

class EventSearchDelegate extends SearchDelegate<String> {
  EventSearchDelegate({required this.onSearch, this.initialQuery = ''}) {
    query = initialQuery;
  }

  final ValueChanged<String> onSearch;
  final String initialQuery;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
          onSearch(query);
        },
        icon: const Icon(Icons.clear),
      ),
      IconButton(
        onPressed: () {
          onSearch(query);
          close(context, query);
        },
        icon: const Icon(Icons.check),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, query);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  void showResults(BuildContext context) {
    onSearch(query);
    super.showResults(context);
  }
}
