import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'color_matching_game_screen.dart';
import 'shape_matching_game_screen.dart';

/// Practice Area Screen with multiple educational game tabs
class PracticeAreaScreen extends StatefulWidget {
  const PracticeAreaScreen({super.key});

  @override
  State<PracticeAreaScreen> createState() => _PracticeAreaScreenState();
}

class _PracticeAreaScreenState extends State<PracticeAreaScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  // Define the tabs and their data
  final List<PracticeTab> _tabs = [
    PracticeTab(
      title: 'Colors',
      icon: CupertinoIcons.paintbrush_fill,
      color: const Color(0xFF4ECDC4),
      screen: const ColorMatchingGameScreen(),
    ),
    PracticeTab(
      title: 'Shapes',
      icon: CupertinoIcons.circle_grid_3x3_fill,
      color: const Color(0xFF45B7D1),
      screen: const ShapeMatchingGameScreen(),
    ),
    PracticeTab(
      title: 'Fruits',
      icon: CupertinoIcons.leaf_arrow_circlepath,
      color: const Color(0xFF96CEB4),
      screen: const PlaceholderGameScreen(title: 'Fruits Matching', subtitle: 'Coming Soon!'),
    ),
    PracticeTab(
      title: 'Cars',
      icon: CupertinoIcons.car_fill,
      color: const Color(0xFFFF6B6B),
      screen: const PlaceholderGameScreen(title: 'Cars Matching', subtitle: 'Coming Soon!'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF8F9FA),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF4ECDC4),
            size: 28,
          ),
        ),
        middle: Text(
          'Practice Area',
          style: TextStyle(
            fontSize: isLandscape ? 18 : 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Custom Tab Bar
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: isLandscape ? screenWidth * 0.02 : screenWidth * 0.04, // Smaller margin in landscape
                vertical: isLandscape ? screenHeight * 0.005 : screenHeight * 0.01, // Smaller vertical margin
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildHorizontalTabs(screenWidth, screenHeight),
              ),
            ),
            
            // Tab Content
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) => tab.screen).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalTabs(double screenWidth, double screenHeight) {
    return Row(
      children: _tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final tab = entry.value;
        final isSelected = index == _currentIndex;
        
        return Expanded(
          child: _buildTabButton(tab, index, isSelected, screenWidth, screenHeight),
        );
      }).toList(),
    );
  }

  Widget _buildTabButton(PracticeTab tab, int index, bool isSelected, 
                        double screenWidth, double screenHeight) {
    final isLandscape = screenWidth > screenHeight;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: isLandscape ? 2 : 4), // Smaller margin in landscape
      decoration: BoxDecoration(
        color: isSelected ? tab.color : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: tab.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? screenWidth * 0.01 : screenWidth * 0.02, // Smaller padding in landscape
          vertical: isLandscape ? screenHeight * 0.008 : screenHeight * 0.015, // Smaller vertical padding
        ),
        onPressed: () {
          _tabController.animateTo(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              color: isSelected ? Colors.white : tab.color,
              size: isLandscape ? screenHeight * 0.025 : screenHeight * 0.035, // Smaller icon in landscape
            ),
            SizedBox(height: isLandscape ? screenHeight * 0.004 : screenHeight * 0.008), // Smaller spacing
            Text(
              tab.title,
              style: TextStyle(
                fontSize: isLandscape ? screenHeight * 0.014 : screenHeight * 0.02, // Smaller text in landscape
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for practice tabs
class PracticeTab {
  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;

  const PracticeTab({
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

/// Placeholder screen for upcoming games
class PlaceholderGameScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlaceholderGameScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenWidth * 0.3,
            height: screenWidth * 0.3,
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.15),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              CupertinoIcons.hammer_fill,
              size: screenWidth * 0.15,
              color: const Color(0xFF4ECDC4),
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              color: const Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.04),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06,
              vertical: screenHeight * 0.015,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
              ),
            ),
            child: Text(
              'This exciting game will be available soon!',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: const Color(0xFF4ECDC4),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
