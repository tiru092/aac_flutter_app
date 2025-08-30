import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/practice_goal.dart';
import '../utils/aac_helper.dart';

class PracticeScreen extends StatefulWidget {
  final PracticeGoal goal;

  const PracticeScreen({super.key, required this.goal});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _headerAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _shakeAnimation;
  
  int currentActivityIndex = 0;
  int starsEarned = 0;
  bool isAnswering = false;

  @override
  void initState() {
    super.initState();
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    );
    
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape = screenWidth > screenHeight;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                // Header with progress and back button
                _buildHeader(context, isLandscape, screenWidth, screenHeight),
                
                // Practice Content
                Expanded(
                  child: _buildPracticeContent(context, isLandscape, screenWidth, screenHeight),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context, bool isLandscape, double screenWidth, double screenHeight) {
    final color = Color(int.parse('FF${widget.goal.color}', radix: 16));
    
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isLandscape ? screenWidth * 0.02 : screenWidth * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.9),
                    color.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top row with back button and stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      Material(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              CupertinoIcons.back,
                              color: Colors.white,
                              size: isLandscape ? 20 : 24,
                            ),
                          ),
                        ),
                      ),
                      
                      // Stars Display
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.star_fill,
                            color: Colors.amber,
                            size: isLandscape ? 20 : 24,
                          ),
                          const SizedBox(width: 8),
                          AutoSizeText(
                            '$starsEarned',
                            style: GoogleFonts.nunito(
                              fontSize: isLandscape ? screenWidth * 0.02 : screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            minFontSize: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Goal Info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          widget.goal.iconEmoji,
                          style: TextStyle(
                            fontSize: isLandscape ? screenWidth * 0.03 : screenWidth * 0.06,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              widget.goal.name,
                              style: GoogleFonts.nunito(
                                fontSize: isLandscape ? screenWidth * 0.025 : screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              minFontSize: 16,
                            ),
                            AutoSizeText(
                              'Activity ${currentActivityIndex + 1} of ${widget.goal.activities.length}',
                              style: GoogleFonts.nunito(
                                fontSize: isLandscape ? screenWidth * 0.015 : screenWidth * 0.035,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              minFontSize: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  _buildProgressBar(isLandscape, screenWidth),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProgressBar(bool isLandscape, double screenWidth) {
    final progress = (currentActivityIndex + 1) / widget.goal.activities.length;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'Progress',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? screenWidth * 0.012 : screenWidth * 0.03,
                color: Colors.white.withOpacity(0.8),
              ),
              maxLines: 1,
              minFontSize: 10,
            ),
            AutoSizeText(
              '${((progress * 100).round())}%',
              style: GoogleFonts.nunito(
                fontSize: isLandscape ? screenWidth * 0.012 : screenWidth * 0.03,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 10,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: isLandscape ? 6 : 8,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPracticeContent(BuildContext context, bool isLandscape, double screenWidth, double screenHeight) {
    if (currentActivityIndex >= widget.goal.activities.length) {
      return _buildCompletionScreen(context, isLandscape, screenWidth, screenHeight);
    }
    
    final currentActivity = widget.goal.activities[currentActivityIndex];
    final practiceItem = currentActivity.items.first; // Simplified for now
    
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * math.sin(_shakeAnimation.value * 2 * math.pi), 0),
          child: Padding(
            padding: EdgeInsets.all(isLandscape ? screenWidth * 0.03 : screenWidth * 0.05),
            child: Column(
              children: [
                // Activity Title and Question
                _buildActivityHeader(currentActivity, isLandscape, screenWidth),
                
                SizedBox(height: isLandscape ? screenHeight * 0.03 : screenHeight * 0.04),
                
                // Question Display
                _buildQuestionDisplay(practiceItem, isLandscape, screenWidth, screenHeight),
                
                SizedBox(height: isLandscape ? screenHeight * 0.03 : screenHeight * 0.04),
                
                // Answer Options
                _buildAnswerOptions(practiceItem, isLandscape, screenWidth, screenHeight),
                
                // Confetti Animation Overlay
                if (_confettiAnimation.value > 0)
                  _buildConfettiOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActivityHeader(PracticeActivity activity, bool isLandscape, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            activity.name,
            style: GoogleFonts.nunito(
              fontSize: isLandscape ? screenWidth * 0.022 : screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1f2937),
            ),
            maxLines: 2,
            minFontSize: 14,
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            activity.description,
            style: GoogleFonts.nunito(
              fontSize: isLandscape ? screenWidth * 0.016 : screenWidth * 0.035,
              color: const Color(0xFF6b7280),
            ),
            maxLines: 3,
            minFontSize: 10,
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionDisplay(PracticeItem item, bool isLandscape, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            const Color(0xFF764ba2).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF667eea).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (item.emoji != null)
            Container(
              padding: EdgeInsets.all(isLandscape ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                item.emoji!,
                style: TextStyle(
                  fontSize: isLandscape ? screenWidth * 0.08 : screenWidth * 0.15,
                ),
              ),
            ),
          
          SizedBox(height: isLandscape ? 16 : 20),
          
          AutoSizeText(
            item.question,
            style: GoogleFonts.nunito(
              fontSize: isLandscape ? screenWidth * 0.02 : screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1f2937),
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            minFontSize: 12,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnswerOptions(PracticeItem item, bool isLandscape, double screenWidth, double screenHeight) {
    return Expanded(
      child: isLandscape
          ? _buildLandscapeAnswerGrid(item, screenWidth, screenHeight)
          : _buildPortraitAnswerList(item, screenWidth, screenHeight),
    );
  }
  
  Widget _buildLandscapeAnswerGrid(PracticeItem item, double screenWidth, double screenHeight) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: math.min(item.options.length, 3),
        childAspectRatio: 2.5,
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenHeight * 0.02,
      ),
      itemCount: item.options.length,
      itemBuilder: (context, index) {
        return _buildAnswerButton(
          item.options[index],
          item.correctAnswer,
          isLandscape: true,
          screenWidth: screenWidth,
        );
      },
    );
  }
  
  Widget _buildPortraitAnswerList(PracticeItem item, double screenWidth, double screenHeight) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: item.options.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: screenHeight * 0.02),
          child: _buildAnswerButton(
            item.options[index],
            item.correctAnswer,
            isLandscape: false,
            screenWidth: screenWidth,
          ),
        );
      },
    );
  }
  
  Widget _buildAnswerButton(
    String answer,
    String correctAnswer, {
    required bool isLandscape,
    required double screenWidth,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAnswering ? null : () => _handleAnswer(answer, correctAnswer),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isLandscape ? 16 : 20,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFe5e7eb),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AutoSizeText(
            answer,
            style: GoogleFonts.nunito(
              fontSize: isLandscape ? screenWidth * 0.018 : screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1f2937),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 12,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCompletionScreen(BuildContext context, bool isLandscape, double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? screenWidth * 0.04 : screenWidth * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Completion Animation
          Container(
            padding: EdgeInsets.all(isLandscape ? 24 : 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10b981),
                  const Color(0xFF059669),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10b981).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '🎉',
                  style: TextStyle(
                    fontSize: isLandscape ? screenWidth * 0.08 : screenWidth * 0.15,
                  ),
                ),
                const SizedBox(height: 16),
                AutoSizeText(
                  'Great Job!',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? screenWidth * 0.03 : screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  minFontSize: 18,
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  'You completed all activities!',
                  style: GoogleFonts.nunito(
                    fontSize: isLandscape ? screenWidth * 0.018 : screenWidth * 0.04,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  minFontSize: 12,
                ),
              ],
            ),
          ),
          
          SizedBox(height: isLandscape ? screenHeight * 0.04 : screenHeight * 0.06),
          
          // Stars Earned
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  CupertinoIcons.star_fill,
                  color: index < starsEarned ? Colors.amber : Colors.grey.withOpacity(0.3),
                  size: isLandscape ? 24 : 32,
                ),
              );
            }),
          ),
          
          SizedBox(height: isLandscape ? screenHeight * 0.04 : screenHeight * 0.06),
          
          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(int.parse('FF${widget.goal.color}', radix: 16)),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isLandscape ? 16 : 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
              ),
              child: AutoSizeText(
                'Continue',
                style: GoogleFonts.nunito(
                  fontSize: isLandscape ? screenWidth * 0.02 : screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                minFontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfettiOverlay() {
    return AnimatedBuilder(
      animation: _confettiAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Opacity(
            opacity: _confettiAnimation.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0x3310b981),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  '⭐✨🎉✨⭐',
                  style: TextStyle(
                    fontSize: 40 * _confettiAnimation.value,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _handleAnswer(String selectedAnswer, String correctAnswer) async {
    if (isAnswering) return;
    
    setState(() {
      isAnswering = true;
    });
    
    if (selectedAnswer == correctAnswer) {
      // Correct answer
      setState(() {
        starsEarned = math.min(starsEarned + 1, 5);
      });
      
      // Play success animation and sound
      _confettiController.forward().then((_) {
        _confettiController.reset();
      });
      
      try {
        await AACHelper.speak('Correct! Great job!');
      } catch (e) {
        // Handle speech error
      }
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      setState(() {
        currentActivityIndex++;
        isAnswering = false;
      });
      
    } else {
      // Wrong answer
      _shakeController.forward().then((_) {
        _shakeController.reset();
      });
      
      try {
        await AACHelper.speak('Try again!');
      } catch (e) {
        // Handle speech error
      }
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        isAnswering = false;
      });
    }
  }
}
