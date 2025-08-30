import 'package:flutter/material.dart';
import 'package:terrago/screens/community_page.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Header section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover New Challenges',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore different categories and find your next mission',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Explore tiles
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildExploreTile(
                      context,
                      title: _exploreData[index]['title'],
                      subtitle: _exploreData[index]['subtitle'],
                      icon: _exploreData[index]['icon'],
                      color: _exploreData[index]['color'],
                      onTap: () => _onTileTap(context, index),
                    );
                  },
                  childCount: _exploreData.length,
                ),
              ),
            ),
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTileTap(BuildContext context, int index) {
    // Handle tile tap - you can add navigation or actions here
    if (_exploreData[index]['title'] == 'Community') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CommunityPage(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tapped: ${_exploreData[index]['title']}'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // Sample explore data - you can customize this
  static const List<Map<String, dynamic>> _exploreData = [
    {
      'title': 'Daily Challenges',
      'subtitle': 'Complete daily tasks for bonus rewards',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
    },
    {
      'title': 'Weekly Goals',
      'subtitle': 'Set and achieve weekly sustainability targets',
      'icon': Icons.flag,
      'color': Colors.green,
    },
    {
      'title': 'Community',
      'subtitle': 'Connect with other eco-warriors',
      'icon': Icons.people,
      'color': Colors.orange,
    },
    {
      'title': 'Achievements',
      'subtitle': 'Unlock badges and milestones',
      'icon': Icons.emoji_events,
      'color': Colors.purple,
    },
    {
      'title': 'Learn',
      'subtitle': 'Discover eco-friendly tips and facts',
      'icon': Icons.school,
      'color': Colors.teal,
    },
    {
      'title': 'Leaderboard',
      'subtitle': 'Compete with friends and family',
      'icon': Icons.leaderboard,
      'color': Colors.red,
    },
  ];
}
