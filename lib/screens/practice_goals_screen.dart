import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/goals_section.dart';

class PracticeGoalsScreen extends StatelessWidget {
  const PracticeGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              CupertinoIcons.back,
              color: Color(0xFF1f2937),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366f1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.star_circle_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    'Practice Goals',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1f2937),
                    ),
                    maxLines: 1,
                    minFontSize: 16,
                  ),
                  AutoSizeText(
                    'Fun activities to improve communication',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF6b7280),
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
        toolbarHeight: 80,
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
      ),
    );
  }
}
