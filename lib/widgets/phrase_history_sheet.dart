import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/data_services_initializer_robust.dart';
import '../utils/aac_helper.dart';

class PhraseHistorySheet extends StatefulWidget {
  const PhraseHistorySheet({super.key});

  @override
  State<PhraseHistorySheet> createState() => _PhraseHistorySheetState();
}

class _PhraseHistorySheetState extends State<PhraseHistorySheet>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PhraseHistoryService _historyService = DataServicesInitializer.instance.phraseHistoryService;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _buildFavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF),
            const Color(0xFF4ECDC4),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.clock_fill,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Phrase History',
            style: TextStyle(
              fontSize: 20 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(18),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(
          fontSize: 16 * AACHelper.getTextSizeMultiplier(),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 16 * AACHelper.getTextSizeMultiplier(),
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(CupertinoIcons.clock),
            text: 'Recent',
          ),
          Tab(
            icon: Icon(CupertinoIcons.star_fill),
            text: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: _historyService.history.isEmpty
          ? _buildEmptyHistory()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _historyService.history.length,
              itemBuilder: (context, index) {
                final item = _historyService.history[index];
                return _buildHistoryItem(item, index);
              },
            ),
    );
  }

  Widget _buildFavoritesTab() {
    return _historyService.favorites.isEmpty
        ? _buildEmptyFavorites()
        : ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _historyService.favorites.length,
            onReorder: (oldIndex, newIndex) async {
              await _historyService.reorderFavorites(oldIndex, newIndex);
              setState(() {});
            },
            itemBuilder: (context, index) {
              final item = _historyService.favorites[index];
              return _buildFavoriteItem(item, index);
            },
          );
  }

  Widget _buildHistoryItem(PhraseHistoryItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFF8F9FA),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isFavorite 
              ? const Color(0xFFFFE66D).withOpacity(0.5)
              : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF),
                const Color(0xFF4ECDC4),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          item.text,
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTime(item.timestamp),
          style: TextStyle(
            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star button
            GestureDetector(
              onTap: () async {
                await _historyService.toggleFavorite(item);
                setState(() {});
                await AACHelper.accessibleHapticFeedback();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.isFavorite 
                      ? const Color(0xFFFFE66D)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isFavorite 
                      ? CupertinoIcons.star_fill 
                      : CupertinoIcons.star,
                  color: item.isFavorite ? Colors.white : Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Speak button
            GestureDetector(
              onTap: () async {
                await AACHelper.speak(item.text);
                await AACHelper.accessibleHapticFeedback();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF51CF66),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.speaker_2_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(PhraseHistoryItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFE66D).withOpacity(0.1),
            const Color(0xFFFFE66D).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE66D),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE66D).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE66D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.star_fill,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        title: Text(
          item.text,
          style: TextStyle(
            fontSize: 16 * AACHelper.getTextSizeMultiplier(),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Favorite phrase',
          style: TextStyle(
            fontSize: 12 * AACHelper.getTextSizeMultiplier(),
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Remove from favorites
            GestureDetector(
              onTap: () async {
                await _historyService.removeFavorite(item.id);
                setState(() {});
                await AACHelper.accessibleHapticFeedback();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CupertinoIcons.trash,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Speak button
            GestureDetector(
              onTap: () async {
                await AACHelper.speak(item.text);
                await AACHelper.accessibleHapticFeedback();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF51CF66),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.speaker_2_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Reorder handle
            const Icon(
              CupertinoIcons.line_horizontal_3,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              CupertinoIcons.clock,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No recent phrases',
            style: TextStyle(
              fontSize: 18 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Speak some sentences to see them here',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE66D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              CupertinoIcons.star,
              size: 50,
              color: Color(0xFFFFE66D),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 18 * AACHelper.getTextSizeMultiplier(),
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Star phrases in history to save them here',
            style: TextStyle(
              fontSize: 14 * AACHelper.getTextSizeMultiplier(),
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}