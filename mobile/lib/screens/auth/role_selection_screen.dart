import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const List<Map<String, String>> _roles = <Map<String, String>>[
    <String, String>{
      'value': 'DONOR',
      'title': 'Donor',
      'subtitle': 'Share food or sealed medicine responsibly',
    },
    <String, String>{
      'value': 'RECEIVER',
      'title': 'Receiver',
      'subtitle': 'Discover verified resources and claim fairly',
    },
    <String, String>{
      'value': 'DOCTOR_PHARMACIST',
      'title': 'Doctor / Pharmacist',
      'subtitle': 'Review medicine safety before public claiming',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _roles.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, String> role = _roles[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              title: Text(role['title']!),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(role['subtitle']!),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pop(role['value']),
            ),
          );
        },
      ),
    );
  }
}
