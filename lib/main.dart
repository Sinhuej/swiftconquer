import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwiftConquer',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text(
            'SWIFTCONQUER\nLoading...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}
