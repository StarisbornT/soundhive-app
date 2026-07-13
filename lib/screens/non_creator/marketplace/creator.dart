import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/lib/dashboard_provider/get_creator_services.dart';
import '../../../components/video_preview_player.dart';
import '../../../model/creator_model.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../utils/utils.dart';
import 'creator_portfolio.dart';

class CreatorProfile extends ConsumerStatefulWidget {
  final CreatorData creator;
  const CreatorProfile({super.key, required this.creator});

  @override
  ConsumerState<CreatorProfile> createState() => _CreatorProfileState();
}

// NOTE: Keep whatever imports your original file already had
// (ConsumerState, AppColors, GoogleFonts, VideoPreviewPlayer,
// CreatorAllReviewsScreen, CreatorPortfolio, MarketOrder, Utils, etc.)
//
// ASSUMPTIONS MADE — please adjust to match your real model/screens:
// 1. Portfolio images come from `widget.creator.portfolioImages` (List<String>).
//    If your model uses a different field name, update `_buildPortfolioSection`.
// 2. Tapping a service card currently opens `CreatorPortfolio` (the same screen
//    the old "View portfolio" button opened). If you have a dedicated booking
//    screen for a single service, swap the destination in `_onServiceTap`.
// 3. Grid density: 1 service → 1 per row, 2-4 services → 2 per row,
//    5-9 → 3 per row, 10+ → 4 per row. Tweak `_serviceCrossAxisCount` if you
//    want different breakpoints.

class _CreatorProfileState extends ConsumerState<CreatorProfile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await ref.read(getCreatorServiceProvider.notifier)
            .getCreatorService(perPage: 10, memberId: widget.creator.userId.toString());
      }
    });
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context, theme),
              const SizedBox(height: 20),

              // 1. Creator name (+ avatar / rating) at the top
              _buildProfileHeader(theme, isDark),
              const SizedBox(height: 30),

              // 2. About / bio
              _buildAboutSection(theme),
              const SizedBox(height: 20),

              // 3. Location
              _buildLocation(theme),
              const SizedBox(height: 30),

              // 4. My Services — selectable boxes/cards, 2-4 per row
              _buildServicesSection(theme, isDark),
              const SizedBox(height: 30),

              // 5 & 6. Portfolio — image gallery, then portfolio video
              _buildPortfolioSection(theme),
              const SizedBox(height: 30),

              // 7. Reviews
              _buildReviewSection(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 1. PROFILE HEADER (name at top)
  // ---------------------------------------------------------------------

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    final serviceState = ref.watch(getCreatorServiceProvider);

    final serviceCount = serviceState.maybeWhen(
      data: (services) => services.length,
      orElse: () => null,
    );

    return Row(
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
            border: Border.all(
              color: AppColors.BUTTONCOLOR.withOpacity(0.3),
              width: 2,
            ),
          ),
        )
            : Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.BUTTONCOLOR.withOpacity(isDark ? 0.8 : 0.6),
            border: Border.all(
              color: AppColors.BUTTONCOLOR.withOpacity(0.3),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.creator.user!.firstName.isNotEmpty
                ? widget.creator.user!.firstName[0].toUpperCase()
                : "?",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                widget.creator.jobTitle ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                serviceCount != null
                    ? '$serviceCount ${serviceCount == 1 ? 'service' : 'services'}'
                    : '',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    '${Utils.getOverallRating(widget.creator).toStringAsFixed(1)} overall rating',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 2. ABOUT
  // ---------------------------------------------------------------------

  Widget _buildAboutSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${widget.creator.businessName?.isNotEmpty == true ? widget.creator.businessName! : "${widget.creator.user?.firstName ?? ''} ${widget.creator.user?.lastName ?? ''}".trim()}',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.creator.bio ?? '',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 3. LOCATION
  // ---------------------------------------------------------------------

  Widget _buildLocation(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          widget.creator.location ?? '',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 4. MY SERVICES (grid of selectable cards, 2-4 per row)
  // ---------------------------------------------------------------------

  int _serviceCrossAxisCount(int count) {
    if (count <= 1) return 1;
    if (count <= 4) return 2;
    if (count <= 9) return 3;
    return 4;
  }

  void _onServiceTap(MarketOrder service) {
    // TODO: point this at your actual "book this service" screen if it
    // differs from the portfolio screen.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatorPortfolio(service: service),
      ),
    );
  }

  Widget _buildServicesSection(ThemeData theme, bool isDark) {
    final serviceState = ref.watch(getCreatorServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Services',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        serviceState.when(
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
          error: (err, stack) => Text(
            "Error: $err",
            style: TextStyle(color: theme.colorScheme.error),
          ),
          loading: () => Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      String imageUrl,
      String title,
      String price,
      MarketOrder service,
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
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: GoogleFonts.roboto(
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 5 & 6. PORTFOLIO (images gallery, then video — one section)
  // ---------------------------------------------------------------------

  Widget _buildPortfolioSection(ThemeData theme) {
    final videoUrl = widget.creator.videoUrl;

    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    if (!hasVideo) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Portfolio',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 15),

        // Image slider / gallery
        // Portfolio video — lives inside the Portfolio section, right after images
        if (hasVideo) ...[
          VideoPreviewPlayer(
            key: ValueKey(videoUrl),
            videoUrl: videoUrl,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 7. REVIEWS
  // ---------------------------------------------------------------------

  Widget _buildReviewSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reviews = widget.creator.reviews;
    final count = reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatorAllReviewsScreen(
                  creator: widget.creator,
                ),
              ),
            );
          },
          child: Text(
            "View all reviews here ($count) >",
            style: TextStyle(
              color: isDark ? const Color(0xFFC5AFFF) : AppColors.BUTTONCOLOR,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
class AvailabilityCalendar extends StatefulWidget {
  final CreatorData creator;
  final Function(DateTime)? onDateSelected;

  const AvailabilityCalendar({
    super.key,
    required this.creator,
    this.onDateSelected,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}
class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  DateTime _currentMonth = DateTime(2025, 6, 1); // Starting with June 2025
  DateTime? _selectedDate;
  final List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    // Convert string dates from API to DateTime objects
    // _availableDates = widget.creator.availabilityCalendar
    //     ?.map((dateStr) => DateTime.parse(dateStr))
    //     .toList() ??
    //     [];
  }

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
        const Text(
          'Availability calendar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
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
          children: weekdays.map((day) =>
              Text(day, style: const TextStyle(color: Colors.white70, fontSize: 12))
          ).toList(),
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
            // Empty cells for days before the 1st of the month
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

    // Format time
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
          // ---- USER + RATING ROW ----
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.PRIMARYCOLOR,
                backgroundImage: review.user?.image != null
                    ? NetworkImage(review.user!.image!)
                    : null,
                child: review.user?.image == null
                    ? Text(
                  review.user?.firstName.substring(0, 1) ?? "?",
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                )
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
              )

            ],
          ),
          const SizedBox(height: 8),
          // ---- REVIEW TEXT ----
          Text(
            review.reviewText ?? "",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 8),

          // ---- TAGS ----
          Wrap(
            spacing: 8,
            children: review.tags
                .map(
                  (t) => Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t.tag,
                  style:
                  const TextStyle(color: Colors.white70, fontSize: 11),
                ),
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
       
        title: Text(
          "Reviews (${creator.reviews.length})",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: creator.reviews
            .map((r) => ReviewItem(review: r))
            .toList(),
      ),
    );
  }
}

