import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/model/event_model.dart';
import 'package:soundhive2/model/user_model.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import 'event_details.dart';

/// Featured events = partner events (Future Fest via Gbedu, and any partner
/// added later). They are promoted in three places:
///   1. a pop-up when the marketplace opens (once per app launch)
///   2. a hero banner on the Marketplace tab
///   3. pinned cards at the top of My Events → Explore
/// Nothing is shown when there are no partner events, so no code change is
/// needed to switch it off after the festival.
List<EventItem> featuredEventsFrom(List<EventItem> events) =>
    events.where((e) => e.isFeatured && !e.isCancelled).toList();

String featuredEventWhen(EventItem e) {
  try {
    if (e.time.trim().isEmpty) {
      return DateFormat('EEE d MMM yyyy').format(DateTime.parse(e.date));
    }
    final dt = DateTime.parse('${e.date} ${e.time}');
    return DateFormat('EEE d MMM yyyy · h:mm a').format(dt);
  } catch (_) {
    return e.date;
  }
}

String featuredEventPrice(WidgetRef ref, EventItem e) =>
    e.isPaid ? 'From ${ref.formatUserCurrency(e.convertedRate)}' : 'Free';

void openFeaturedEvent(BuildContext context, EventItem event, User user) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EventDetails(event: event, user: user)),
  );
}

Widget _eventImage(EventItem e) {
  if (e.image.isEmpty) return Utils.buildImagePlaceholder();
  return CachedNetworkImage(
    imageUrl: e.image,
    fit: BoxFit.cover,
    placeholder: (_, __) => Container(color: Colors.grey[900]),
    errorWidget: (_, __, ___) => Utils.buildImagePlaceholder(),
  );
}

Widget _featuredChip() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.BUTTONCOLOR,
      borderRadius: BorderRadius.circular(100),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: Colors.white, size: 14),
        SizedBox(width: 4),
        Text(
          'FEATURED EVENT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    ),
  );
}

// ── Pop-up ────────────────────────────────────────────────────────────────

class FeaturedEventPopup {
  static bool _shownThisLaunch = false;

  /// Shows the pop-up for the first featured event, once per app launch.
  static Future<void> maybeShow(
    BuildContext context, {
    required List<EventItem> featured,
    required User user,
    VoidCallback? onSeeAll,
  }) async {
    if (_shownThisLaunch || featured.isEmpty) return;
    _shownThisLaunch = true;

    final event = featured.first;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Consumer(
        builder: (_, ref, __) => Dialog(
          backgroundColor: AppColors.BACKGROUNDCOLOR,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.BUTTONCOLOR.withOpacity(0.6)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    AspectRatio(aspectRatio: 1, child: _eventImage(event)),
                    Positioned(top: 12, left: 12, child: _featuredChip()),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoRow(Icons.calendar_today_outlined,
                          featuredEventWhen(event)),
                      const SizedBox(height: 6),
                      _infoRow(Icons.location_on_outlined, event.location),
                      const SizedBox(height: 14),
                      Text(
                        'Tickets are selling now. ${featuredEventPrice(ref, event)}.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.BUTTONCOLOR,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        openFeaturedEvent(context, event, user);
                      },
                      child: const Text(
                        'Get Tickets',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (onSeeAll != null && featured.length > 1)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          onSeeAll();
                        },
                        child: Text(
                          'See all ${featured.length} events',
                          style: const TextStyle(color: AppColors.PRIMARY_ACCENT),
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ── Banner / pinned cards ─────────────────────────────────────────────────

/// Large swipeable card(s) for featured events, with a section header.
class FeaturedEventsBanner extends StatelessWidget {
  final List<EventItem> events;
  final User? user;
  final VoidCallback? onSeeAll;
  final EdgeInsets padding;

  const FeaturedEventsBanner({
    super.key,
    required this.events,
    required this.user,
    this.onSeeAll,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty || user == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.BUTTONCOLOR, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Don't miss out",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('All events',
                      style: TextStyle(color: AppColors.PRIMARY_ACCENT)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 230,
          child: events.length == 1
              ? Padding(
                  padding: padding,
                  child: FeaturedEventCard(event: events.first, user: user!),
                )
              : PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  padEnds: false,
                  itemCount: events.length,
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.only(
                      left: i == 0 ? padding.left : 6,
                      right: 6,
                    ),
                    child: FeaturedEventCard(event: events[i], user: user!),
                  ),
                ),
        ),
      ],
    );
  }
}

class FeaturedEventCard extends ConsumerWidget {
  final EventItem event;
  final User user;

  const FeaturedEventCard({super.key, required this.event, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => openFeaturedEvent(context, event, user),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _eventImage(event),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.25, 1.0],
                ),
              ),
            ),
            Positioned(top: 12, left: 12, child: _featuredChip()),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${featuredEventWhen(event)}  ·  ${event.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          featuredEventPrice(ref, event),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.BUTTONCOLOR,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        onPressed: () => openFeaturedEvent(context, event, user),
                        child: const Text('Get Tickets',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
