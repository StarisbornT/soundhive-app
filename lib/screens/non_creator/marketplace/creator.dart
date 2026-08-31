import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/lib/dashboard_provider/get_creator_services.dart';
import '../../../components/creator_profile_widgets.dart';
import '../../../components/video_preview_player.dart';
import '../../../model/creator_model.dart';
import '../../../model/creator_profile_models.dart';
import '../../../model/service_model.dart';
import '../../../utils/utils.dart';
import 'creator_portfolio.dart';

// ---------------------------------------------------------------------
// Portfolio Overhaul — rebuilt Creator Profile
//
// Replaces the old single long-scroll layout with 6 tabs:
//   Overview | Portfolio | Experience | Services | Skills | Reviews
//
// NOTE / ASSUMPTIONS — please adjust to match your real model/screens:
// 1. Extra data that doesn't exist on CreatorData yet (portfolio media,
//    experience, skills, availability, trust badges) is sourced through
//    `CreatorProfileExtras.fromCreator(widget.creator)` — see
//    creator_profile_models.dart for the TODOs on wiring real API fields.
// 2. Tapping a service card still opens `CreatorPortfolio` (the Service
//    Detail screen). Swap the destination in `_onServiceTap` if you have
//    a dedicated booking flow.
// 3. Grid density for the Services tab: 1 service → 1 per row, 2-4 → 2,
//    5-9 → 3, 10+ → 4. Tweak `_serviceCrossAxisCount` as needed.
// ---------------------------------------------------------------------

class CreatorProfile extends ConsumerStatefulWidget {
  final CreatorData creator;
  const CreatorProfile({super.key, required this.creator});

  @override
  ConsumerState<CreatorProfile> createState() => _CreatorProfileState();
}

class _CreatorProfileState extends ConsumerState<CreatorProfile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final CreatorProfileExtras _extras;

  static const _tabs = ['Overview', 'Portfolio', 'Experience', 'Services', 'Skills', 'Reviews'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _extras = CreatorProfileExtras.fromCreator(widget.creator);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await ref
            .read(getCreatorServiceProvider.notifier)
            .getCreatorService(perPage: 10, memberId: widget.creator.userId.toString());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _overallRating => Utils.getOverallRating(widget.creator);

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context, theme),
                  const SizedBox(height: 12),
                  _buildProfileHeader(theme, isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,   // <-- important, see note below
              padding: EdgeInsets.zero,           // remove TabBar's own outer padding
              labelPadding: const EdgeInsets.only(right: 24), // space between tabs, none on the left
              labelColor: AppColors.BUTTONCOLOR,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: AppColors.BUTTONCOLOR,
              indicatorSize: TabBarIndicatorSize.label, // makes the underline hug the text width, not the padded cell
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
            // TabBar(
            //   controller: _tabController,
            //   isScrollable: true,
            //   labelColor: AppColors.BUTTONCOLOR,
            //   unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            //   indicatorColor: AppColors.BUTTONCOLOR,
            //   labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            //   tabs: _tabs.map((t) => Tab(text: t)).toList(),
            // ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(theme),
                  _buildPortfolioTab(theme),
                  _buildExperienceTab(theme),
                  _buildServicesTab(theme, isDark),
                  _buildSkillsTab(theme),
                  _buildReviewsTab(theme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // HEADER — name, avatar, rating, trust badges (shown above the tabs so
  // they're visible regardless of which tab is active)
  // ---------------------------------------------------------------------

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    final serviceState = ref.watch(getCreatorServiceProvider);
    final serviceCount = serviceState.maybeWhen(
      data: (services) => services.length,
      orElse: () => null,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.creator.user?.image != null
            ? Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(widget.creator.user?.image ?? ''),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: AppColors.BUTTONCOLOR.withOpacity(0.3), width: 2),
          ),
        )
            : Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.BUTTONCOLOR.withOpacity(isDark ? 0.8 : 0.6),
            border: Border.all(color: AppColors.BUTTONCOLOR.withOpacity(0.3), width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.creator.user!.firstName.isNotEmpty
                ? widget.creator.user!.firstName[0].toUpperCase()
                : "?",
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.creator.businessName ??
                    "${widget.creator.user?.firstName} ${widget.creator.user?.lastName}",
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w400),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.creator.jobTitle ?? "",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${_overallRating.toStringAsFixed(1)} overall rating',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                  ),
                  if (serviceCount != null) ...[
                    const SizedBox(width: 10),
                    Text(
                      '· $serviceCount ${serviceCount == 1 ? 'service' : 'services'}',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ],
              ),
              if (_extras.trustBadges.isNotEmpty) ...[
                const SizedBox(height: 8),
                TrustBadgeRow(badges: _extras.trustBadges),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // TAB 1 — OVERVIEW: about, location, availability, ratings summary
  // ---------------------------------------------------------------------

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection(theme),
          const SizedBox(height: 20),
          _buildLocation(theme),
          if (_extras.availability != null) ...[
            const SizedBox(height: 20),
            AvailabilityCard(info: _extras.availability!),
          ],
          if (_extras.ratingDistribution.totalReviews > 0) ...[
            const SizedBox(height: 24),
            Text(
              'Ratings',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 12),
            RatingBreakdown(distribution: _extras.ratingDistribution, compact: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${widget.creator.businessName?.isNotEmpty == true ? widget.creator.businessName! : "${widget.creator.user?.firstName ?? ''} ${widget.creator.user?.lastName ?? ''}".trim()}',
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        Text(
          widget.creator.bio ?? "",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildLocation(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.location_on_outlined, color: theme.colorScheme.onSurface.withOpacity(0.7), size: 20),
        const SizedBox(width: 10),
        Text(
          widget.creator.location ?? "",
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // TAB 2 — PORTFOLIO: verified work grid (See all / +N more) + video
  // ---------------------------------------------------------------------

  Widget _buildPortfolioTab(ThemeData theme) {
    final videoUrl = widget.creator.videoUrl;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortfolioGrid(
            items: _extras.portfolio,
            previewCount: 6,
            crossAxisCount: 3,
            onSeeAll: _extras.portfolio.isEmpty
                ? null
                : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatorFullPortfolioScreen(items: _extras.portfolio),
              ),
            ),
          ),
          if (hasVideo) ...[
            const SizedBox(height: 24),
            Text(
              'Video Portfolio',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 15),
            VideoPreviewPlayer(key: ValueKey(videoUrl), videoUrl: videoUrl),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TAB 3 — EXPERIENCE: timeline of previous projects / clients / achievements
  // ---------------------------------------------------------------------

  Widget _buildExperienceTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ExperienceTimeline(entries: _extras.experience),
    );
  }

  // ---------------------------------------------------------------------
  // TAB 4 — SERVICES (unchanged grid of bookable service cards)
  // ---------------------------------------------------------------------

  int _serviceCrossAxisCount(int count) {
    if (count <= 1) return 1;
    if (count <= 4) return 2;
    if (count <= 9) return 3;
    return 4;
  }

  void _onServiceTap(ServiceItem service) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatorPortfolio(service: service)),
    );
  }

  Widget _buildServicesTab(ThemeData theme, bool isDark) {
    final serviceState = ref.watch(getCreatorServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: serviceState.when(
        data: (services) {
          if (services.isEmpty) {
            return Text(
              "No services available",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            );
          }

          final crossAxisCount = _serviceCrossAxisCount(services.length);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(
                service.serviceImage ?? '',
                service.serviceName,
                ref.formatUserCurrency(service.convertedRate),
                service,
                theme,
                isDark,
              );
            },
          );
        },
        error: (err, stack) => Text("Error: $err", style: TextStyle(color: theme.colorScheme.error)),
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      ),
    );
  }

  Widget _buildServiceCard(
      String imageUrl,
      String title,
      String price,
      ServiceItem service,
      ThemeData theme,
      bool isDark,
      ) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => _onServiceTap(service),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // TAB 5 — SKILLS
  // ---------------------------------------------------------------------

  Widget _buildSkillsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SkillChips(skills: _extras.skills),
    );
  }

  // ---------------------------------------------------------------------
  // TAB 6 — REVIEWS: multi-category breakdown + individual review list
  // ---------------------------------------------------------------------

  Widget _buildReviewsTab(ThemeData theme, bool isDark) {
    final reviews = widget.creator.reviews;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RatingBreakdown(distribution: _extras.ratingDistribution),
          const SizedBox(height: 20),
          if (reviews.isEmpty)
            Text(
              'No reviews yet',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            )
          else ...[
            ...reviews.take(3).map((r) => ReviewItem(review: r)),
            if (reviews.length > 3)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreatorAllReviewsScreen(creator: widget.creator)),
                  );
                },
                child: Text(
                  "View all reviews (${reviews.length}) >",
                  style: TextStyle(
                    color: isDark ? const Color(0xFFC5AFFF) : AppColors.BUTTONCOLOR,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Full portfolio gallery — destination for "See all" / "+N more"
// ---------------------------------------------------------------------

class CreatorFullPortfolioScreen extends StatelessWidget {
  final List<PortfolioItem> items;
  const CreatorFullPortfolioScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Portfolio (${items.length})', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(item.thumbnailUrl, fit: BoxFit.cover),
                if (item.isVideo)
                  const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------
// AvailabilityCalendar, ReviewItem, CreatorAllReviewsScreen — unchanged
// from the original file, kept here so this file is a drop-in replacement.
// ---------------------------------------------------------------------

class AvailabilityCalendar extends StatefulWidget {
  final CreatorData creator;
  final Function(DateTime)? onDateSelected;

  const AvailabilityCalendar({super.key, required this.creator, this.onDateSelected});

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  DateTime _currentMonth = DateTime(2025, 6, 1);
  DateTime? _selectedDate;
  final List<DateTime> _availableDates = [];

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  bool _isDateAvailable(DateTime date) {
    return _availableDates.any((availableDate) =>
    availableDate.year == date.year &&
        availableDate.month == date.month &&
        availableDate.day == date.day);
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Availability calendar',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                  onPressed: _previousMonth,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildCalendarGrid(startingWeekday, daysInMonth),
      ],
    );
  }

  Widget _buildCalendarGrid(int startingWeekday, int daysInMonth) {
    final List<String> weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
          weekdays.map((day) => Text(day, style: const TextStyle(color: Colors.white70, fontSize: 12))).toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startingWeekday - 1 + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startingWeekday - 1) {
              return const SizedBox.shrink();
            }

            final day = index - startingWeekday + 2;
            final currentDate = DateTime(_currentMonth.year, _currentMonth.month, day);
            final isAvailable = _isDateAvailable(currentDate);
            final isSelected = _selectedDate != null &&
                _selectedDate!.year == currentDate.year &&
                _selectedDate!.month == currentDate.month &&
                _selectedDate!.day == currentDate.day;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                setState(() {
                  _selectedDate = currentDate;
                });
                widget.onDateSelected?.call(currentDate);
              }
                  : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue
                      : isAvailable
                      ? AppColors.BUTTONCOLOR
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ReviewItem extends StatelessWidget {
  final Review review;

  const ReviewItem({required this.review, super.key});

  String formatReviewDate(String dateString) {
    final date = DateTime.parse(dateString);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'pm' : 'am';

    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    return "$day/$month/$year, $hour:$minute$ampm";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.PRIMARYCOLOR,
                backgroundImage: review.user?.image != null ? NetworkImage(review.user!.image!) : null,
                child: review.user?.image == null
                    ? Text(review.user?.firstName.substring(0, 1) ?? "?",
                    style: const TextStyle(fontSize: 20, color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "${review.user?.firstName} ${review.user?.lastName}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  review.rating,
                      (i) => const Icon(Icons.star, color: Colors.amber, size: 16),
                ),
              ),
              Text(
                formatReviewDate(review.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF7C7C88)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.reviewText,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: review.tags
                .map(
                  (t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t.tag, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            )
                .toList(),
          ),
          if (review.media != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                review.media?.filePath ?? "",
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CreatorAllReviewsScreen extends StatelessWidget {
  final CreatorData creator;

  const CreatorAllReviewsScreen({required this.creator, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reviews (${creator.reviews.length})", style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: creator.reviews.map((r) => ReviewItem(review: r)).toList(),
      ),
    );
  }
}