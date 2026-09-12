import 'package:flutter/material.dart';
import 'package:stephenscalender2024/myevents/my_events.dart';
import 'package:stephenscalender2024/myevents/screens/addevent.dart';
import 'package:stephenscalender2024/services/user_role_service.dart';

class PortalPage extends StatefulWidget {
  const PortalPage({super.key});

  @override
  State<PortalPage> createState() => _PortalPageState();
}

class _PortalPageState extends State<PortalPage> {
  late Future<bool> _canManageFuture;

  @override
  void initState() {
    super.initState();
    _canManageFuture = UserRoleService.canManageEvents();
  }

  Future<void> _refreshRole() async {
    setState(() {
      _canManageFuture = UserRoleService.canManageEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Society Portal')),
      body: FutureBuilder<bool>(
        future: _canManageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final canManage = snapshot.data ?? false;
          if (!canManage) {
            return RefreshIndicator(
              onRefresh: _refreshRole,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                children: const [
                  Icon(Icons.lock_outline, size: 58),
                  SizedBox(height: 14),
                  Text(
                    'Portal access is restricted to allowlisted society POCs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Ask your coordinator to add your college email in the `society_admins` allowlist.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            children: [
              _portalCard(
                context,
                title: 'Add New Event',
                subtitle: 'Create and publish events for your society.',
                icon: Icons.add_circle_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddEvent()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _portalCard(
                context,
                title: 'Manage Existing Events',
                subtitle: 'Edit title, time, location and remove outdated entries.',
                icon: Icons.edit_calendar_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditEventPage()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _portalCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: CircleAvatar(
          radius: 22,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
