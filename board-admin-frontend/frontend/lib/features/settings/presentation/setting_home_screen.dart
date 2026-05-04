import 'package:flutter/material.dart';
import 'setting_group_screen.dart';

class SettingHomeScreen extends StatelessWidget {
  const SettingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = const [
      'MEETING_CIRCULAR',
      'AGENDA',
      'PAPER',
      'USER_MANAGEMENT',
      'COMMENT',
      'GENERAL',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Card(
            child: ListTile(
              title: Text(group),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingGroupScreen(group: group),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
