import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/creator/artist_arena/add_songs.dart';
import 'package:soundhive2/screens/creator/artist_arena/edit_artist_profile.dart';
import 'package:soundhive2/screens/creator/artist_arena/song_screen.dart';
import 'package:soundhive2/screens/creator/creator_dashboard.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/lib/dashboard_provider/artist_statistics_provider.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../model/song_stats.dart';
import '../../../model/user_model.dart';

class ArtistProfileScreen extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const ArtistProfileScreen({super.key, required this.user});

  @override
  ConsumerState<ArtistProfileScreen> createState() => _ArtistProfileScreenState();
}


class _ArtistProfileScreenState extends ConsumerState<ArtistProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(getArtistProfileStatistics.notifier).getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statsAsync = ref.watch(getArtistProfileStatistics);
    final user = widget.user.user?.artist;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) {
            final songStats = stats.data.songStats;
            final performance = stats.data.performance;
            final earnings = stats.data.earnings;

            final hasSongs = songStats.created > 0;

            return Column(
              children: [
                _ProfileHeader(user: user, theme: theme, isDark: isDark),
                Expanded(
                  child: hasSongs
                      ? _StatsAndGraphSection(
                    songStats: songStats,
                    performance: performance,
                    earnings: earnings,
                    theme: theme,
                    isDark: isDark,
                  )
                      : _EmptySongsSection(theme: theme, isDark: isDark),
                ),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
          error: (err, _) => Center(
            child: Text(
              'Failed to load statistics: $err',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Empty state widget
class _EmptySongsSection extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  const _EmptySongsSection({required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/bag.png',
              height: 120,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
            const SizedBox(height: 20),
            Text(
              'No published songs',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have not published any song on Soundhive yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            // Add new song button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: RoundedButton(
                title: '+ Add new Song',
                color: theme.colorScheme.primary,
                borderWidth: 0,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddSongScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Stats and Graph Section
class _StatsAndGraphSection extends ConsumerWidget {
  final SongStats songStats;
  final Performance performance;
  final Earnings earnings;
  final ThemeData theme;
  final bool isDark;

  const _StatsAndGraphSection({
    required this.songStats,
    required this.performance,
    required this.earnings,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Statistics section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(
                title: 'Created',
                value: Utils.formatNumber(songStats.created),
                theme: theme,
              ),
              _StatItem(
                title: 'Published',
                value: Utils.formatNumber(songStats.published),
                theme: theme,
              ),
              _StatItem(
                title: 'Rejected',
                value: Utils.formatNumber(songStats.rejected),
                theme: theme,
              ),
              _StatItem(
                title: 'Under Review',
                value: Utils.formatNumber(songStats.underReview),
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Performance section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                title: 'Plays',
                value: performance.plays,
                theme: theme,
              ),
              _StatItem(
                title: 'Followers',
                value: performance.followers,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Earnings section with graph
          _EarningsSection(
            earnings: earnings,
            performance: performance,
            songStats: songStats,
            theme: theme,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Recent Activity or Additional Sections
          _AdditionalInfoSection(
            songStats: songStats,
            theme: theme,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ✅ Earnings Section with Graph
class _EarningsSection extends ConsumerWidget {
  final Earnings earnings;
  final Performance performance;
  final SongStats songStats;
  final ThemeData theme;
  final bool isDark;

  const _EarningsSection({
    required this.earnings,
    required this.performance,
    required this.songStats,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Earnings',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SongScreen(),
                  ),
                );
              },
              child: Text(
                'View songs',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Total Earnings
        Text(
          earnings.formattedTotal,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),

        // Payment Status
        Row(
          children: [
            Icon(
              Icons.check_circle,
              color: double.parse(earnings.formattedTotal) >= 0
                  ? Colors.green
                  : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 5),
            Text(
              double.parse(earnings.formattedTotal) >= 0
                  ? 'Paid to Cre8Vest Wallet'
                  : 'Pending payment',
              style: TextStyle(
                color: double.parse(earnings.formattedTotal) >= 0
                    ? Colors.green
                    : Colors.orange,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Time Filter
        _TimeFilterButtons(theme: theme, isDark: isDark),
        const SizedBox(height: 15),

        // Graph Widget
        _EarningsGraph(
          performance: performance,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // Quick Stats
        _QuickStats(
          earnings: earnings,
          performance: performance,
          songStats: songStats,
          theme: theme,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _TimeFilterButtons extends StatefulWidget {
  final ThemeData theme;
  final bool isDark;
  const _TimeFilterButtons({required this.theme, required this.isDark});

  @override
  State<_TimeFilterButtons> createState() => _TimeFilterButtonsState();
}

class _TimeFilterButtonsState extends State<_TimeFilterButtons> {
  String _selectedFilter = 'Last 30 days';

  final List<String> _filters = [
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
    'This Year'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? widget.theme.colorScheme.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? widget.theme.colorScheme.primary
                        : widget.theme.dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : widget.theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ✅ Earnings Graph Widget
class _EarningsGraph extends ConsumerWidget {
  final Performance performance;
  final ThemeData theme;
  final bool isDark;

  const _EarningsGraph({
    required this.performance,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample data for the graph - replace with actual data
    final List<double> earningsData = [1000, 2500, 1800, 3200, 2800, 4000, 3500];
    final maxEarnings = earningsData.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B0C23) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          // Graph Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings Trend',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Peak: ${ref.formatCreatorCurrency(maxEarnings)}',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Graph Bars
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: earningsData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  final height = (value / maxEarnings) * 110;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 20,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Quick Stats Section
class _QuickStats extends StatelessWidget {
  final Earnings earnings;
  final Performance performance;
  final SongStats songStats;
  final ThemeData theme;
  final bool isDark;

  const _QuickStats({
    required this.earnings,
    required this.performance,
    required this.songStats,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    double parseFormattedNumber(String formatted) {
      if (formatted.isEmpty) return 0;
      formatted = formatted.toLowerCase().trim();

      if (formatted.endsWith('k')) {
        return (double.tryParse(formatted.replaceAll('k', '')) ?? 0) * 1000;
      } else if (formatted.endsWith('m')) {
        return (double.tryParse(formatted.replaceAll('m', '')) ?? 0) * 1000000;
      } else if (formatted.endsWith('b')) {
        return (double.tryParse(formatted.replaceAll('b', '')) ?? 0) * 1000000000;
      }

      return double.tryParse(formatted) ?? 0;
    }

    final playsValue = parseFormattedNumber(performance.plays.toString());
    final followersValue = parseFormattedNumber(performance.followers);
    final publishedCount = songStats.published;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B0C23) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Performance Insights',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickStatItem(
                label: 'Avg. Plays per Song',
                value: publishedCount > 0
                    ? (playsValue / publishedCount).toStringAsFixed(1)
                    : '0',
                theme: theme,
              ),
              _QuickStatItem(
                label: 'Conversion Rate',
                value: playsValue > 0
                    ? '${((followersValue / playsValue) * 100).toStringAsFixed(1)}%'
                    : '0%',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ Quick Stat Item
class _QuickStatItem extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _QuickStatItem({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ✅ Additional Info Section
class _AdditionalInfoSection extends StatelessWidget {
  final SongStats songStats;
  final ThemeData theme;
  final bool isDark;

  const _AdditionalInfoSection({
    required this.songStats,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B0C23) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Song Distribution',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _DistributionItem(
            label: 'Published Songs',
            value: songStats.published,
            total: songStats.created,
            color: Colors.green,
            theme: theme,
          ),
          _DistributionItem(
            label: 'Under Review',
            value: songStats.underReview,
            total: songStats.created,
            color: Colors.orange,
            theme: theme,
          ),
          _DistributionItem(
            label: 'Rejected Songs',
            value: songStats.rejected,
            total: songStats.created,
            color: Colors.red,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

// ✅ Distribution Item
class _DistributionItem extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  final ThemeData theme;

  const _DistributionItem({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (value / total) * 100 : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

// ✅ Stat Item Widget
class _StatItem extends StatelessWidget {
  final String title;
  final dynamic value;
  final ThemeData theme;

  const _StatItem({
    required this.title,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Artist? user;
  final ThemeData theme;
  final bool isDark;
  const _ProfileHeader({
    required this.user,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const double waveHeight = 220;
    const double avatarRadius = 40;

    return SizedBox(
      height: waveHeight + 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Background cover photo
          Container(
            height: waveHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(user?.coverPhoto ?? ''),
                fit: BoxFit.cover,
                colorFilter: isDark
                    ? ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                )
                    : null,
              ),
            ),
          ),

          // Gradient overlay for better text readability
          Container(
            height: waveHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // 2. Profile details (Avatar + Username + Edit Button)
          Positioned(
            top: waveHeight - (avatarRadius / 2),
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar + Username stacked vertically
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: CircleAvatar(
                          radius: avatarRadius - 3,
                          backgroundImage: user?.profilePhoto != null
                              ? NetworkImage(user!.profilePhoto!)
                              : const AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.userName ?? "Damian_sings",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                const Spacer(),

                // Edit Profile button on the right
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditArtistProfile(user: user!),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Edit profile",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Back button
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatorDashboard(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

