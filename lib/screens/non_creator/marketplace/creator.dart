import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../../model/creator_model.dart';
import '../../../utils/utils.dart';
class CreatorProfile extends ConsumerStatefulWidget {
  final CreatorData creator;
  const CreatorProfile({super.key, required this.creator});

  @override
  _CreatorProfileState createState() => _CreatorProfileState();
}

class _CreatorProfileState extends ConsumerState<CreatorProfile> {
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
              AvailabilityCalendar(
                creator: widget.creator,
                onDateSelected: (selectedDate) {
                  // Handle date selection
                  print('Selected date: $selectedDate');
                },
              )
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
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
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
        widget.creator.profileImage != null
            ? Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(widget.creator.profileImage ?? ''),
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
            widget.creator.member!.firstName.isNotEmpty
                ? widget.creator.member!.firstName[0].toUpperCase()
                : "?",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded( // ✅ Added this
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.creator.member?.firstName} ${widget.creator.member?.lastName}",
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
          'About ${widget.creator.member?.firstName} ${widget.creator.member?.lastName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.creator.bioDescription ?? '',
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
      padding: EdgeInsets.all(10),
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
        SizedBox(
          height: 200, // Fixed height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.creator.rates?.length ?? 0,
            itemBuilder: (context, index) {
              final rate = widget.creator.rates?[index];
              if (rate == null) return const SizedBox.shrink();

              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 20),
                child: _buildServiceCard(
                  widget.creator.profileImage ?? '',
                  rate.productName,
                  Utils.formatCurrency(rate.amount),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(String imageUrl, String title, String price) {
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
                // Handle view portfolio
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
            right: 15, // <-- Add this line to let it expand
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
  List<DateTime> _availableDates = [];

  @override
  void initState() {
    super.initState();
    // Convert string dates from API to DateTime objects
    _availableDates = widget.creator.availabilityCalendar
        ?.map((dateStr) => DateTime.parse(dateStr))
        .toList() ??
        [];
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