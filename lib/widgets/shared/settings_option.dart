// lib/widgets/shared/settings_option.dart
import 'package:flutter/material.dart';

class SettingsOption extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const SettingsOption({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }
}