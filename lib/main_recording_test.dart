import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'screens/recording_test_screen.dart';

void main() {
  runApp(const RecordingTestApp());
}

class RecordingTestApp extends StatelessWidget {
  const RecordingTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Recording Test',
      debugShowCheckedModeBanner: false,
      home: RecordingTestScreen(),
    );
  }
}