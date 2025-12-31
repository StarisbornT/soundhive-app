import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/eventProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/event_stats_provider.dart';
import 'package:soundhive2/model/event_model.dart';
import 'package:soundhive2/screens/creator/events/event_details_screen.dart';
import '../../../model/event_stats_model.dart';
import 'create_event_screen.dart';

class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}
class _EventScreenState extends ConsumerState<EventScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatusFilter = "Upcoming";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshData();
    });
  }

  Future<void> _refreshData() async {
    await ref.read(eventStatsProvider.notifier).getStats();
    ref.invalidate(eventProvider('published'));
    ref.invalidate(eventProvider('pending'));
    ref.invalidate(eventProvider('rejected'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final service = ref.watch(eventStatsProvider);
    final services = service.whenOrNull(
      data: (data) => data.data.events,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Event Management',
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 22
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: RawMaterialButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen())
            );
          },
          fillColor: theme.colorScheme.primary,
          shape: const CircleBorder(),
          elevation: 6,
          child: Icon(
            Icons.add,
            color: theme.colorScheme.onPrimary,
            size: 36,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildStatsHeader(services, theme: theme),
              const SizedBox(height: 20),
              Divider(color: theme.dividerColor),
              _buildMainTabs(theme: theme, isDark: isDark),
              const SizedBox(height: 15),
              // Add status filters here - BEFORE the TabBarView
              _buildStatusFilters(theme: theme, isDark: isDark),
              const SizedBox(height: 20),
              // Add search bar here - BEFORE the TabBarView
              _buildSearchBar(theme: theme, isDark: isDark),
              const SizedBox(height: 20),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final publishedState = ref.watch(eventProvider('published'));
                        return publishedState.when(
                          data: (serviceResponse) =>
                              buildEventList(
                                serviceResponse.data.data,
                                "No published event",
                                theme: theme,
                                isDark: isDark,
                              ),
                          loading: () => Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          error: (error, _) => Center(
                            child: Text(
                              'Error: $error',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final pendingState = ref.watch(eventProvider('pending'));
                        return pendingState.when(
                          data: (serviceResponse) =>
                              buildEventList(
                                serviceResponse.data.data,
                                "No event under review",
                                theme: theme,
                                isDark: isDark,
                              ),
                          loading: () => Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          error: (error, _) => Center(
                            child: Text(
                              'Error: $error',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final rejectedState = ref.watch(eventProvider('rejected'));
                        return rejectedState.when(
                          data: (serviceResponse) =>
                              buildEventList(
                                serviceResponse.data.data,
                                "No event services",
                                theme: theme,
                                isDark: isDark,
                              ),
                          loading: () => Center(
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          error: (error, _) => Center(
                            child: Text(
                              'Error: $error',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update this method to only build the list, not the filters/search bar
  Widget buildEventList(List<EventItem> items, String emptyMessage,
      {required ThemeData theme, required bool isDark}) {
    final filteredItems = _filterEvents(items);
    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
      );
    }

    // Only return the ListView, no filters or search bar
    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsScreen(event: filteredItems[index]),
              ),
            );
          },
          child: _eventCard(
            filteredItems[index],
            theme: theme,
            isDark: isDark,
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(Events? event, {required ThemeData theme}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem(
          event?.approved.toString() ?? '0',
          "Published",
          theme: theme,
        ),
        _statItem(
          event?.pending.toString() ?? '0',
          "Under review",
          theme: theme,
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, {required ThemeData theme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold
          ),
        ),
        Text(
          label,
          style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabs({required ThemeData theme, required bool isDark}) {
    return TabBar(
      controller: _tabController,
      indicatorColor: theme.colorScheme.primary,
      indicatorWeight: 3,
      labelColor: theme.colorScheme.onSurface,
      unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
      tabs: const [
        Tab(text: "Published"),
        Tab(text: "Under review"),
        Tab(text: "Rejected"),
      ],
    );
  }

  List<EventItem> _filterEvents(List<EventItem> allEvents) {
    // First filter by status
    List<EventItem> filtered = allEvents.where((event) {
      // Assuming EventItem has an eventStatus property
      // Convert both to lowercase for case-insensitive comparison
      String eventStatus = event.eventStatus.toLowerCase();
      String selectedFilter = _selectedStatusFilter.toLowerCase();

      if (selectedFilter == 'upcoming') {
        return eventStatus == 'upcoming';
      } else if (selectedFilter == 'ongoing') {
        return eventStatus == 'ongoing';
      } else if (selectedFilter == 'completed') {
        return eventStatus == 'completed';
      } else if (selectedFilter == 'cancelled') {
        return eventStatus == 'cancelled';
      }
      return true; // Show all if filter not recognized
    }).toList();

    return filtered;
  }

  Widget _buildStatusFilters({required ThemeData theme, required bool isDark}) {
    final filters = ["Upcoming", "Ongoing", "Completed", "Cancelled"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedStatusFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatusFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? const Color(0xFF1A1A1A) : Colors.grey[100]!),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar({required ThemeData theme, required bool isDark}) {
    return TextField(
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: "Search",
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(
          Icons.search,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0D0214) : Colors.grey[100],
        contentPadding: const EdgeInsets.all(0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _eventCard(EventItem item, {required ThemeData theme, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: (item.image.isNotEmpty)
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  child: Icon(
                    Icons.event,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            )
                : Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                        Icons.location_on_outlined,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        size: 14
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          item.location,
                          style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 12
                          ),
                          overflow: TextOverflow.ellipsis
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "${_formatDate(item.date)}, ${item.time}",
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.type == "PAID" ? "${item.currency}${item.amount}" : item.type,
            style: TextStyle(
              color: item.type == "PAID"
                  ? Colors.green
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: item.type == "PAID" ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}