import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/goals_section.dart';

class EnhancedGoalsScreen extends StatelessWidget {
  const EnhancedGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.yellow, size: 28),
              SizedBox(width: 8),
              Text(
                'Practice Goals',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: GoalsSection(),
          ),
        ),
    );
  }
}
