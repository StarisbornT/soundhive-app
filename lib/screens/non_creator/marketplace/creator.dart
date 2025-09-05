import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/app_colors.dart';

import 'package:soundhive2/lib/dashboard_provider/get_creator_services.dart';
import '../../../model/creator_model.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../utils/utils.dart';
import 'creator_portfolio.dart';
class CreatorProfile extends ConsumerStatefulWidget {
  final CreatorData creator;
  const CreatorProfile({super.key, required this.creator});

  @override
  _CreatorProfileState createState() => _CreatorProfileState();
}

class _CreatorProfileState extends ConsumerState<CreatorProfile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await ref.read(getCreatorServiceProvider.notifier)
            .getCreatorService(perPage: 10, memberId: widget.creator.userId);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              const SizedBox(height: 20),
              _buildProfileHeader(),
              const SizedBox(height: 30),
              _buildAboutSection(),
              const SizedBox(height: 30),
              _buildSocialIcons(),
              const SizedBox(height: 20),
              _buildLocation(),
              const SizedBox(height: 30),
              _buildServicesSection(),
              const SizedBox(height: 30),
              // AvailabilityCalendar(
              //   creator: widget.creator,
              //   onDateSelected: (selectedDate) {
              //     // Handle date selection
              //     print('Selected date: $selectedDate');
              //   },
              // )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              // Handle back button press
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
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
          ),
        )
            : Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.BUTTONCOLOR,
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
                "${widget.creator.user?.firstName} ${widget.creator.user?.lastName}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis, // Optional
              ),
              const SizedBox(height: 5),
              Text(
                widget.creator.jobTitle ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis, // Optional
              ),
              const SizedBox(height: 5),
              const Text(
                '10 services • 200 clients',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 5),
                  Text(
                    '4.8 overall rating',
                    style: TextStyle(
                      color: Colors.white70,
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

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${widget.creator.user?.firstName} ${widget.creator.user?.lastName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.creator.bio ?? '',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      children: [
        _buildSocialIcon(FontAwesomeIcons.x),
        const SizedBox(width: 15),
        _buildSocialIcon(Icons.facebook),
        const SizedBox(width: 15),
        _buildSocialIcon(FontAwesomeIcons.instagram),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          widget.creator.location ?? '',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final serviceState = ref.watch(getCreatorServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Services',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        serviceState.when(
          data: (services) {
            if (services.isEmpty) {
              return const Text(
                "No services available",
                style: TextStyle(color: Colors.white70),
              );
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];

                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 20),
                    child: _buildServiceCard(
                      service.serviceImage ?? '',
                      service.serviceName,
                      Utils.formatCurrency(service.rate),
                      service
                    ),
                  );
                },
              ),
            );
          },
          error: (err, stack) => Text(
            "Error: $err",
            style: const TextStyle(color: Colors.red),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }


  Widget _buildServiceCard(String imageUrl, String title, String price, MarketOrder service) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreatorPortfolio(service: service),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1429),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
              child: const Text(
                'View portfolio',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 15,
            right: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 2, // or more if you want
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: GoogleFonts.roboto(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      )
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
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