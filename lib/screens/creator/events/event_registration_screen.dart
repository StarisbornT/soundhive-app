import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/utils/app_colors.dart';

import 'package:soundhive2/lib/dashboard_provider/getMyTicketProvider.dart';

import '../../../model/event_model.dart';

class EventRegistrationScreen extends ConsumerStatefulWidget {
  final EventItem event;
  const EventRegistrationScreen({super.key, required this.event});

  @override
  ConsumerState<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends ConsumerState<EventRegistrationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load initial data
    ref.read(getMyTicketProvider.notifier).getRegistration(
      eventId: widget.event.id,
    );

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final notifier = ref.read(getMyTicketProvider.notifier);
    final isLoadingMore = notifier.isLoadingMore;
    final isLastPage = notifier.isLastPage;

    if (!isLoadingMore && !isLastPage) {
      notifier.getRegistration(
        eventId: widget.event.id,
        loadMore: true,
      );
    }
  }

  @override
  void didUpdateWidget(covariant EventRegistrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If eventId changes, reload data
    if (oldWidget.event.id != widget.event.id) {
      ref.read(getMyTicketProvider.notifier).getRegistration(
        eventId: widget.event.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ticketState = ref.watch(getMyTicketProvider);
    final tickets = ref.read(getMyTicketProvider.notifier).allServices;
    final isLastPage = ref.read(getMyTicketProvider.notifier).isLastPage;
    final isLoadingMore = ref.read(getMyTicketProvider.notifier).isLoadingMore;
    final event = widget.event;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ticketState.when(
        data: (ticketModel) {
          final ticket = ticketModel.data.data;
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrations for ${event.title}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${event.type} • ${event.date} ${event.time.isNotEmpty}',
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        size: 60,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 16),
                Text(
                  '${ticketModel.data.total.toString()} Registration${ticketModel.data.total != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                if (tickets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 60,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No registrations yet',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Registrations will appear here',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tickets.length + (isLastPage ? 0 : 1),
                    separatorBuilder: (context, index) {
                      if (index < tickets.length - 1) {
                        return Divider(color: theme.dividerColor.withOpacity(0.5));
                      }
                      return const SizedBox.shrink();
                    },
                    itemBuilder: (context, index) {
                      // Loading more indicator
                      if (index >= tickets.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: isLoadingMore
                                ? CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            )
                                : IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: theme.colorScheme.primary,
                              ),
                              onPressed: _loadMore,
                            ),
                          ),
                        );
                      }

                      final ticket = tickets[index];
                      final userName = ticket.user.firstName;
                      final userEmail = ticket.user.email;
                      final userImage = ticket.user.image;
                      final registrationDate = ticket.createdAt;

                      // Format date
                      String formattedDate = 'Unknown date';
                      try {
                        final date = DateTime.parse(registrationDate);
                        formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                      } catch (e) {
                        formattedDate = registrationDate;
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundImage: userImage != null
                                ? NetworkImage(userImage)
                                : null,
                            backgroundColor: theme.colorScheme.primary,
                            child: userImage == null
                                ? Text(
                              userName.isNotEmpty
                                  ? userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: userEmail.isNotEmpty
                              ? Text(
                            userEmail,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.dividerColor,
                              ),
                            ),
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 48
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load registrations',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(getMyTicketProvider.notifier).getRegistration(
                    eventId: widget.event.id,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}