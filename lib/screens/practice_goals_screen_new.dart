import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/goals_section.dart';

class PracticeGoalsScreen extends StatelessWidget {
  const PracticeGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              CupertinoIcons.back,
              color: Color(0xFF2D4356),
              size: 24,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Practice Goals',
            style: TextStyle(
              fontFamily: 'Atkinson',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D4356),
            ),
          ),
        ),
        body: const SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Goals Section - now displayed as full screen content
                GoalsSection(),
                SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      );
  }
}
