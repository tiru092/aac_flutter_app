import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/offline_features_service.dart';
import '../utils/aac_helper.dart';
import 'dart:convert';

/// Enterprise-grade offline features showcase screen
class OfflineFeaturesScreen extends StatefulWidget {
  const OfflineFeaturesScreen({super.key});

  @override
  State<OfflineFeaturesScreen> createState() => _OfflineFeaturesScreenState();
}

class _OfflineFeaturesScreenState extends State<OfflineFeaturesScreen> with TickerProviderStateMixin {
  final OfflineFeaturesService _offlineService = OfflineFeaturesService.instance;
  
  // Data state
  Map<String, dynamic> _insights = {};
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _recommendations = [];
  
  // UI state
  bool _isLoading = true;
  bool _isUpdating = false;
  int _selectedTabIndex = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOfflineData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOfflineData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final insights = await _offlineService.generateUsageInsights();
      final achievements = await _offlineService.getOfflineAchievements();
      final recommendations = await _offlineService.getPersonalizedRecommendations();
      
      setState(() {
        _insights = insights;
        _achievements = achievements;
        _recommendations = recommendations;
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Failed to load offline data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF4ECDC4),
        middle: const Text(
          '🚀 Offline Features',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: _isUpdating 
              ? const CupertinoActivityIndicator()
              : const Icon(CupertinoIcons.refresh, color: Colors.white),
          onPressed: _isUpdating ? null : _refreshData,
        ),
      ),
      child: Material(
        child: SafeArea(
          child: Column(
              children: [
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF4ECDC4),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF4ECDC4),
                    tabs: const [
                      Tab(text: 'Insights'),
                      Tab(text: 'Achievements'),
                      Tab(text: 'Suggestions'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                ),
              ),
            // Tab content
            Expanded(
              child: _isLoading 
                  ? const Center(child: CupertinoActivityIndicator())
                  : Material(
                      color: Colors.transparent,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildInsightsTab(),
                          _buildAchievementsTab(),
                          _buildRecommendationsTab(),
                          _buildAnalyticsTab(),
                        ],
                      ),
                    ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_insights.isEmpty) {
      return _buildEmptyState(
        'No Insights Yet',
        'Start using the communication board to generate personalized insights!',
        CupertinoIcons.chart_bar,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInsightCard(
          'Communication Summary',
          [
            _buildInsightRow('Total Communications', '${_insights['totalCommunications'] ?? 0}'),
            _buildInsightRow('Items Explored', '${_insights['progressMetrics']?['itemsExplored'] ?? 0}'),
            _buildInsightRow('Daily Average', '${(_insights['averageDailyUsage'] ?? 0).toStringAsFixed(1)}'),
          ],
          CupertinoIcons.chat_bubble_2_fill,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          'Usage Patterns',
          [
            _buildInsightRow('Peak Hour', _formatPeakHour(_insights['peakUsageHour'])),
            _buildInsightRow('Consistency Score', '${((_insights['progressMetrics']?['consistencyScore'] ?? 0) * 100).toStringAsFixed(1)}%'),
            _buildInsightRow('Communication Velocity', '${(_insights['communicationVelocity'] ?? 0).toStringAsFixed(2)} items/min'),
          ],
          CupertinoIcons.clock,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildMostUsedItemsCard(),
        const SizedBox(height: 16),
        _buildHourlyUsageChart(),
      ],
    );
  }

  Widget _buildAchievementsTab() {
    if (_achievements.isEmpty) {
      return _buildEmptyState(
        'No Achievements Yet',
        'Keep using the app to unlock achievements and milestones!',
        CupertinoIcons.star,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Unlocked Achievements',
          style: TextStyle(
            fontSize: 20 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ..._achievements.map((achievement) => _buildAchievementCard(achievement)).toList(),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return _buildEmptyState(
        'No Recommendations Yet',
        'Use the communication board more to get personalized suggestions!',
        CupertinoIcons.lightbulb,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Personalized Suggestions',
          style: TextStyle(
            fontSize: 20 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Based on your communication patterns and preferences',
          style: TextStyle(
            fontSize: 14 * AACHelper.getTextSizeMultiplier(),
            color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ..._recommendations.map((recommendation) => _buildRecommendationCard(recommendation)).toList(),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAnalyticsCard(
          'Offline Analytics',
          'All analytics are processed locally on your device',
          CupertinoIcons.device_phone_portrait,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCard(
          'Privacy Protection',
          'Your communication data never leaves your device',
          CupertinoIcons.lock_shield,
          Colors.purple,
        ),
        const SizedBox(height: 16),
        _buildAnalyticsCard(
          'Smart Caching',
          'Frequently used items are cached for instant access',
          CupertinoIcons.archivebox,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildExportSection(),
      ],
    );
  }

  Widget _buildInsightCard(String title, List<Widget> children, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15 * AACHelper.getTextSizeMultiplier(),
              color: AACHelper.isHighContrastEnabled ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostUsedItemsCard() {
    final mostUsed = _insights['mostUsedItems'] as List<dynamic>? ?? [];
    
    if (mostUsed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.star_fill, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Most Used Items',
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...mostUsed.take(5).map((item) {
              final count = item['count'] ?? 0;
              final maxCount = mostUsed.isNotEmpty ? mostUsed[0]['count'] ?? 1 : 1;
              final percentage = (count / maxCount * 100).round();
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item ${item['itemId'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                            fontWeight: FontWeight.w500,
                            color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
                          ),
                        ),
                        Text(
                          '$count uses',
                          style: TextStyle(
                            fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                            color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyUsageChart() {
    final hourlyPatterns = _insights['hourlyPatterns'] as Map<String, dynamic>? ?? {};
    
    if (hourlyPatterns.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxUsage = hourlyPatterns.values.isEmpty ? 1 : 
        hourlyPatterns.values.reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.chart_bar_alt_fill, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Usage by Hour',
                  style: TextStyle(
                    fontSize: 18 * AACHelper.getTextSizeMultiplier(),
                    fontWeight: FontWeight.bold,
                    color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(24, (hour) {
                  final usage = hourlyPatterns[hour.toString()] ?? 0;
                  final height = usage > 0 ? (usage / maxUsage * 120).clamp(4.0, 120.0) : 4.0;
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 8,
                        height: height,
                        decoration: BoxDecoration(
                          color: usage > 0 ? const Color(0xFF4ECDC4) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hour.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 10 * AACHelper.getTextSizeMultiplier(),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            CupertinoIcons.star_fill,
            color: Colors.amber,
            size: 24,
          ),
        ),
        title: Text(
          achievement['title'] ?? 'Unknown Achievement',
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              achievement['description'] ?? '',
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                achievement['category']?.toString().toUpperCase() ?? 'ACHIEVEMENT',
                style: TextStyle(
                  fontSize: 10 * AACHelper.getTextSizeMultiplier(),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4ECDC4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    Color priorityColor;
    IconData priorityIcon;
    
    switch (recommendation['priority']) {
      case 'high':
        priorityColor = Colors.red;
        priorityIcon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityIcon = CupertinoIcons.info_circle_fill;
        break;
      default:
        priorityColor = Colors.blue;
        priorityIcon = CupertinoIcons.lightbulb_fill;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            priorityIcon,
            color: priorityColor,
            size: 24,
          ),
        ),
        title: Text(
          'Item ${recommendation['itemId'] ?? 'Unknown'}',
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              recommendation['reason'] ?? 'Recommended for you',
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recommendation['priority']?.toString().toUpperCase()} PRIORITY',
                    style: TextStyle(
                      fontSize: 10 * AACHelper.getTextSizeMultiplier(),
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Score: ${recommendation['score'] ?? 0}',
                  style: TextStyle(
                    fontSize: 12 * AACHelper.getTextSizeMultiplier(),
                    color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String description, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.bold,
            color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 14 * AACHelper.getTextSizeMultiplier(),
            color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Container(
      decoration: BoxDecoration(
        color: AACHelper.isHighContrastEnabled ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: AACHelper.isHighContrastEnabled
            ? Border.all(color: Colors.black, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.doc_text, color: Colors.teal, size: 24),
            ),
            title: Text(
              'Export Offline Data',
              style: TextStyle(
                fontSize: 17 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Export your analytics and insights for backup or analysis',
              style: TextStyle(
                fontSize: 14 * AACHelper.getTextSizeMultiplier(),
                color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
              ),
            ),
            trailing: const Icon(CupertinoIcons.chevron_right, color: Colors.grey),
            onTap: () => _exportOfflineData(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String description, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20 * AACHelper.getTextSizeMultiplier(),
                fontWeight: FontWeight.bold,
                color: AACHelper.isHighContrastEnabled ? Colors.black : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16 * AACHelper.getTextSizeMultiplier(),
                color: AACHelper.isHighContrastEnabled ? Colors.black54 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeakHour(dynamic hour) {
    if (hour == null) return 'Unknown';
    final h = int.tryParse(hour.toString()) ?? 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$displayHour:00 $period';
  }

  Future<void> _refreshData() async {
    setState(() {
      _isUpdating = true;
    });

    await _loadOfflineData();

    setState(() {
      _isUpdating = false;
    });
  }

  Future<void> _exportOfflineData() async {
    try {
      showCupertinoDialog(
        context: context,
        builder: (context) => const CupertinoAlertDialog(
          title: Text('Exporting Data'),
          content: CupertinoActivityIndicator(),
        ),
      );

      final exportData = await _offlineService.exportOfflineStatistics();
      
      Navigator.pop(context); // Close loading dialog
      
      if (exportData.isNotEmpty) {
        // In a real app, you would save this to a file or share it
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Export Complete'),
            content: Text('Exported ${exportData.length} data sections including insights, achievements, and analytics.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Export Failed'),
          content: Text('Failed to export offline data: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
}
