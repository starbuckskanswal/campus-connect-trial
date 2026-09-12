

import 'package:stephenscalender2024/signup/components/body.dart';

import 'Society.dart';

class SocietyIconResolver {
  static List<Society>? _societies;

  static Future<String> getIconForSociety(String societyName) async {
    // Load once
    _societies ??= await loadSocieties();

    // Find matching society
    final society = _societies!.firstWhere(
          (s) => s.name == societyName,
      orElse: () => Society(id: '', name: '', icon: ''),
    );

    return society.icon; // may be empty
  }
}
