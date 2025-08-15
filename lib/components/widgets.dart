import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soundhive2/components/rounded_button.dart';
import '../lib/dashboard_provider/getAccountBalanceProvider.dart';
import '../model/user_model.dart';
import '../screens/dashboard/transaction_history.dart';
import '../screens/dashboard/withdraw.dart';
import '../utils/app_colors.dart';
import '../utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'image_picker.dart';
import 'label_text.dart';

class WalletCard extends StatelessWidget {
  final String balance;
  final VoidCallback onAddFunds;

  const WalletCard({
    Key? key,
    required this.balance,
    required this.onAddFunds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF4D3490),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Soundhive Vest wallet',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            Utils.formatCurrency(balance),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),

          // Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onAddFunds,
                icon: Icon(Icons.add, color: Color(0xFF4D3490), size: 18),
                label: Text(
                  'Add funds',
                  style: TextStyle(color: Color(0xFF4D3490), fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WithdrawScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.download, color: Colors.white, size: 18),
                label: Text(
                  'Withdraw',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => TransactionHistory(),
              //   ),
              // );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1A191E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  'View transaction history',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PortfolioUploadSection extends StatefulWidget {
  final String title;
  final ValueNotifier<File?> coverImageNotifier;
  final ValueNotifier<File?> imageFileNotifier;
  final ValueNotifier<File?> audioFileNotifier;
  final TextEditingController linkController;
  final ValueNotifier<List<String>> selectedFormatsNotifier;

  const PortfolioUploadSection({
    super.key,
    required this.title,
    required this.coverImageNotifier,
    required this.imageFileNotifier,
    required this.audioFileNotifier,
    required this.linkController,
    required this.selectedFormatsNotifier,
  });

  @override
  State<PortfolioUploadSection> createState() => _PortfolioUploadSectionState();
}

class _PortfolioUploadSectionState extends State<PortfolioUploadSection> {
  final List<Map<String, String>> portfolioFormat = [
    {'label': 'Image', 'value': 'image'},
    {'label': 'Link', 'value': 'link'},
    {'label': 'Audio', 'value': 'audio'},
  ];

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;
      widget.audioFileNotifier.value = File(file.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          DashedBorderBox(
            child: Column(
              children: [
                ImagePickerComponent(
                  labelText: 'Cover Image',
                  imageNotifier: widget.coverImageNotifier,
                  hintText: "Upload Image",
                  validator: (value) {
                    if (value == null) {
                      return ' image is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<List<String>>(
                  valueListenable: widget.selectedFormatsNotifier,
                  builder: (context, selectedFormats, _) {
                    return Column(
                      children: [
                        LabeledMultiSelectField(
                          label: "Portfolio Format",
                          items: portfolioFormat,
                          selectedValues: selectedFormats,
                          onChanged: (values) {
                            // Clear data for formats that were removed
                            final removedFormats = widget.selectedFormatsNotifier.value
                                .where((format) => !values.contains(format))
                                .toList();

                            for (final format in removedFormats) {
                              if (format == 'audio') {
                                widget.audioFileNotifier.value = null;
                              } else if (format == 'image') {
                                widget.imageFileNotifier.value = null;
                              } else if (format == 'link') {
                                widget.linkController.clear();
                              }
                            }

                            widget.selectedFormatsNotifier.value = values;
                          },
                        ),
                        const SizedBox(height: 10),
                        if (selectedFormats.contains('audio'))
                          ValueListenableBuilder<File?>(
                            valueListenable: widget.audioFileNotifier,
                            builder: (context, audioFile, _) {
                              return FileUploadField(
                                label: 'Audio file',
                                uploadText: audioFile != null
                                    ? 'Audio Selected'
                                    : 'Upload Audio',
                                supportedFileTypes: 'Supported file types: mp3',
                                maxFileSize: 'Max file size: 10MB',
                                uploadIcon: Icons.upload_file_outlined,
                                onTap: _pickAudioFile,
                                fileName: audioFile?.path.split('/').last,
                              );
                            },
                          ),
                        if (selectedFormats.contains('audio')) const SizedBox(height: 10),
                        if (selectedFormats.contains('link'))
                          LabeledTextField(
                            label: 'Link',
                            controller: widget.linkController,
                            hintText: 'Enter Link',
                          ),
                        if (selectedFormats.contains('link')) const SizedBox(height: 10),
                        if (selectedFormats.contains('image'))
                          ImagePickerComponent(
                            labelText: 'Image File',
                            imageNotifier: widget.imageFileNotifier,
                            hintText: "Upload Image",
                            validator: (value) {
                              if (value == null) {
                                return ' image is required';
                              }
                              return null;
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FileUploadField extends StatelessWidget {
  final String label;
  final String uploadText;
  final String supportedFileTypes;
  final String maxFileSize;
  final VoidCallback? onTap; // Callback when the upload area is tapped
  final IconData uploadIcon; // Icon for the upload area
  final String? fileName;

  const FileUploadField({
    super.key,
    required this.label,
    this.uploadText = 'Upload File',
    this.supportedFileTypes = 'Supported file types: All',
    this.maxFileSize = 'Max file size: N/A',
    this.onTap,
    this.fileName,
    this.uploadIcon = Icons.cloud_upload_outlined, // Default upload icon
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.WHITECOLOR,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap, // Call the provided onTap callback
          child: Container(
            width: double.infinity, // Full width
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black, // Black background for the upload area
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
              border: Border.all(color: Colors.white38), // Subtle border
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  uploadIcon,
                  size: 30,
                  color: Colors.white, // White icon
                ),
                const SizedBox(height: 16),
                Text(
                  uploadText,
                  style: const TextStyle(
                    color: Colors.white, // White text for upload prompt
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                if (fileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    fileName!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Text(
                  supportedFileTypes,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54, // Faded text for file types
                    fontSize: 12,
                  ),
                ),
                Text(
                  maxFileSize,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54, // Faded text for file size
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(digitsOnly);
    final newString = _formatter.format(number);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class DashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color? bgColor;
  const DashedBorderBox({super.key, required this.child, this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: bgColor ?? const Color(0xFF0C0513),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color? color;

  _DashedBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 2.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = color ?? const Color(0xFF656566)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8));
    final path = Path()..addRRect(rect);
    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dest.addPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CalendarBottomSheet extends StatefulWidget {
  final List<DateTime> initialSelectedDates;

  const CalendarBottomSheet({
    super.key,
    this.initialSelectedDates = const [],
  });

  @override
  State<CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<CalendarBottomSheet> {
  late DateTime _currentMonth;
  final Set<DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    // Initialize current month to today's month or the month of the first selected date
    _currentMonth = DateTime.now();
    if (widget.initialSelectedDates.isNotEmpty) {
      _selectedDates.addAll(widget.initialSelectedDates.map(_normalizeDate));
      _currentMonth = _normalizeDate(widget.initialSelectedDates.first);
    }
  }

  // Normalizes a date to YYYY-MM-DD format without time components
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Toggles the selection state of a date
  void _toggleDateSelection(DateTime date) {
    setState(() {
      final normalizedDate = _normalizeDate(date);
      if (_selectedDates.contains(normalizedDate)) {
        _selectedDates.remove(normalizedDate);
      } else {
        _selectedDates.add(normalizedDate);
      }
    });
  }

  // Checks if a date is selected
  bool _isDateSelected(DateTime date) {
    return _selectedDates.contains(_normalizeDate(date));
  }

  // Builds the header for the month navigation
  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat.yMMMM().format(_currentMonth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF656566)),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                        _currentMonth.year, _currentMonth.month - 1, 1);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF656566)),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                        _currentMonth.year, _currentMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the row for weekdays (SUN, MON, etc.)
  Widget _buildWeekdaysRow() {
    final List<String> weekdays = [
      'SUN',
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT'
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays.map((day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54, // Faded color for weekdays
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Builds individual day cells in the calendar grid
  Widget _buildDayCell(DateTime date) {
    final bool isSelected = _isDateSelected(date);
    final bool isCurrentMonth =
        date.month == _currentMonth.month && date.year == _currentMonth.year;

    return GestureDetector(
      onTap: isCurrentMonth
          ? () => _toggleDateSelection(date)
          : null, // Only allow selection for current month days
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.BUTTONCOLOR
              : Colors.transparent, // Highlight selected dates
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          date.day.toString(),
          style: TextStyle(
            color: isCurrentMonth
                ? (isSelected
                    ? Colors.white
                    : Colors.white) // White for current month days
                : Colors.white38, // Faded for days outside current month
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Builds the main calendar grid
  Widget _buildCalendarGrid() {
    final DateTime firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final int daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final int firstWeekday =
        firstDayOfMonth.weekday % 7; // 0 for Sunday, 1 for Monday, etc.

    List<Widget> dayCells = [];

    // Add empty cells for days before the 1st of the month
    for (int i = 0; i < firstWeekday; i++) {
      // Calculate date for previous month's day
      final DateTime prevMonthDay =
          firstDayOfMonth.subtract(Duration(days: firstWeekday - i));
      dayCells.add(_buildDayCell(prevMonthDay));
    }

    // Add cells for days of the current month
    for (int i = 1; i <= daysInMonth; i++) {
      final DateTime date =
          DateTime(_currentMonth.year, _currentMonth.month, i);
      dayCells.add(_buildDayCell(date));
    }

    // Add empty cells for days after the last day of the month to fill the last row
    final int remainingCells =
        42 - dayCells.length; // Max 6 rows * 7 days = 42 cells
    for (int i = 1; i <= remainingCells; i++) {
      final DateTime nextMonthDay =
          DateTime(_currentMonth.year, _currentMonth.month, daysInMonth + i);
      dayCells.add(_buildDayCell(nextMonthDay));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling for the grid itself
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0, // Make cells square
      ),
      itemCount: dayCells.length,
      itemBuilder: (context, index) => dayCells[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A191E), // Dark background color from image
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content
        children: [
          // Drag handle (optional, common for bottom sheets)
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // "Select Date(s)" header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select Date(s)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Selected dates display (e.g., 17/06/2025, 18/06/2025)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _selectedDates.isEmpty
                  ? 'No dates selected'
                  : _selectedDates
                      .map((d) => DateFormat('dd/MM/yyyy').format(d))
                      .join(', '),
              style: const TextStyle(
                color: Color(0xFFC5AFFF),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12), // Divider line
          const SizedBox(height: 16),

          // Month navigation
          _buildMonthHeader(),
          const SizedBox(height: 8),

          // Weekdays row
          _buildWeekdaysRow(),
          const SizedBox(height: 8),

          // Calendar grid
          _buildCalendarGrid(),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(null); // Pop with null if cancelled
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white, // Text color
                    side:
                        const BorderSide(color: Colors.white54), // Border color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Sort the selected dates before returning
                    final sortedDates = _selectedDates.toList()..sort();
                    Navigator.of(context)
                        .pop(sortedDates); // Pop with selected dates
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.BUTTONCOLOR, // Purple button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Create calendar',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Component 2: DateSelectionInput ---
// This is the input field that triggers the bottom sheet.
class DateSelectionInput extends StatefulWidget {
  final List<DateTime> initialSelectedDates;
  final ValueChanged<List<DateTime>>? onDatesSelected;

  const DateSelectionInput({
    super.key,
    this.initialSelectedDates = const [],
    this.onDatesSelected,
  });

  @override
  State<DateSelectionInput> createState() => _DateSelectionInputState();
}

class _DateSelectionInputState extends State<DateSelectionInput> {
  List<DateTime> _selectedDates = [];

  @override
  void initState() {
    super.initState();
    _selectedDates = List.from(widget.initialSelectedDates);
  }

  // Formats the list of selected dates into a display string
  String _getDisplayString() {
    if (_selectedDates.isEmpty) {
      return 'Select dates you are available';
    }
    // Sort dates to display them in order
    final sortedDates = _selectedDates.toList()..sort();
    return sortedDates
        .map((d) => DateFormat('dd/MM/yyyy').format(d))
        .join(', ');
  }

  // Shows the calendar bottom sheet
  Future<void> _showCalendarBottomSheet() async {
    final result = await showModalBottomSheet<List<DateTime>>(
      context: context,
      isScrollControlled:
          true, // Allows the bottom sheet to take full height if needed
      backgroundColor:
          Colors.transparent, // Important for custom rounded corners
      builder: (context) {
        return CalendarBottomSheet(initialSelectedDates: _selectedDates);
      },
    );

    if (result != null) {
      setState(() {
        _selectedDates = result;
      });
      widget.onDatesSelected?.call(result); // Notify parent widget
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showCalendarBottomSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black, // Black background for the input field
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
              border: Border.all(color: Colors.white38), // Subtle border
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getDisplayString(),
                    style: TextStyle(
                      color: _selectedDates.isEmpty
                          ? Colors.white54
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined, // Calendar icon
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ServiceActionSheet extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ServiceActionSheet({
    Key? key,
    this.onView,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            icon: Icons.remove_red_eye_outlined,
            label: 'View service',
            onTap: onView,
          ),
          const SizedBox(height: 20),

          // 👇 Only show Edit if onEdit is not null
          if (onEdit != null) ...[
            _buildItem(
              icon: Icons.edit_outlined,
              label: 'Edit service',
              onTap: onEdit,
            ),
            const SizedBox(height: 20),
          ],

          _buildItem(
            icon: Icons.delete_outline,
            label: 'Delete service',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          )
        ],
      ),
    );
  }
}

class PaymentMethodSelector extends ConsumerStatefulWidget {
  final void Function(String) onSelected;
  final User user;

  const PaymentMethodSelector({super.key, required this.onSelected, required this.user});

  @override
  ConsumerState<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends ConsumerState<PaymentMethodSelector> {
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    if(widget.user.account != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(getAccountBalance.notifier).getAccountBalance(widget.user.account!.accountId);
      });
    }

  }

  void _showPaymentOptions(BuildContext context) {
    int selectedOption = _selectedMethod == 'Paystack Checkout' ? 1 : 0;
    final serviceState = ref.watch(getAccountBalance);
    final balanceText = widget.user.account == null
        ? '₦0.00'
        : serviceState.when(
      data: (response) => Utils.formatCurrency(response.data.accountBalance),
      loading: () => '₦0.00', // fallback text while loading
      error: (err, _) => '₦0.00',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBottomSheet) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How do you want to pay?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Don’t worry, the service provider will not be paid until the job has been completed.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentOption(
                    context,
                    title: 'Soundhive Vest - $balanceText',
                    icon: Icons.account_balance_wallet,
                    selected: selectedOption == 0,
                    onTap: () => setStateBottomSheet(() => selectedOption = 0),
                    radioColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    context,
                    title: 'Paystack Checkout',
                    icon: Icons.payment,
                    selected: selectedOption == 1,
                    onTap: () => setStateBottomSheet(() => selectedOption = 1),
                    radioColor: Colors.white,
                  ),

                  const SizedBox(height: 24),

                  RoundedButton(
                    title: 'Proceed',
                    onPressed: () {
                      String method = selectedOption == 0
                          ? 'savehaven'
                          : 'Paystack Checkout';

                      setState(() => _selectedMethod = method);
                      widget.onSelected(method);
                      Navigator.pop(context);
                    },
                    color: const Color(0xFF4D3490),
                    borderWidth: 0,
                    borderRadius: 25.0,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = ref.watch(getAccountBalance);
    final balanceText = widget.user.account == null
        ? '₦0.00'
        : serviceState.when(
      data: (response) => Utils.formatCurrency(response.data.accountBalance),
      loading: () => '₦0.00', // fallback text while loading
      error: (err, _) => '₦0.00',
    );
    return GestureDetector(
      onTap: () => _showPaymentOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:  Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedMethod == "savehaven" ? 'Soundhive Vest - $balanceText'  : "Paystack Checkout",
              style: TextStyle(
                color: _selectedMethod == null ? Colors.grey : Colors.white,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_outlined, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
      BuildContext context, {
        required String title,
        required IconData icon,
        required bool selected,
        required VoidCallback onTap,
        required Color radioColor,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? radioColor : Colors.grey),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: radioColor,
            ),
          ],
        ),
      ),
    );
  }
}



