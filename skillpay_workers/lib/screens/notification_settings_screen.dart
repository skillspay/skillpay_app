import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _promoEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Manage your notification preferences',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive alerts on your device'),
              value: _pushEnabled,
              activeColor: const Color(0xFFFFC107),
              onChanged: (val) => setState(() => _pushEnabled = val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive updates via email'),
              value: _emailEnabled,
              activeColor: const Color(0xFFFFC107),
              onChanged: (val) => setState(() => _emailEnabled = val),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Promotional Messages'),
              subtitle: const Text('Offers, discounts, and tips'),
              value: _promoEnabled,
              activeColor: const Color(0xFFFFC107),
              onChanged: (val) => setState(() => _promoEnabled = val),
            ),
          ],
        ),
      ),
    );
  }
}
