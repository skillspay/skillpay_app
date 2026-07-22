import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  final String title;
  const AuthScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Placeholder for $title')),
    );
  }
}
