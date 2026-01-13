import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/eventProvider.dart';
import 'package:soundhive2/model/event_model.dart';
import 'package:soundhive2/screens/creator/events/event_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/image_picker.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import '../../../components/widgets.dart';
import '../../../lib/dashboard_provider/event_stats_provider.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventItem event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  // Controllers
  late TextEditingController eventTitleController;
  late TextEditingController eventTimeController;
  late TextEditingController eventLocationController;
  late TextEditingController eventDescriptionController;
  late TextEditingController eventTicketLimitController;
  late TextEditingController eventAmountController;
  late TextEditingController eventTypeController;

  // Date & Time
  DateTime? selectedEventDate;
  TimeOfDay? selectedEventTime;

  // Image
  final ValueNotifier<File?> eventImageNotifier = ValueNotifier<File?>(null);
  String? uploadedImageUrl;

  // Event type
  String? selectedEventType;

  final List<Map<String, String>> eventTypeOptions = [
    {'label': 'Free', 'value': 'free'},
    {'label': 'Paid', 'value': 'paid'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with event data
    eventTitleController = TextEditingController(text: widget.event.title);
    eventLocationController = TextEditingController(text: widget.event.location);
    eventDescriptionController = TextEditingController(text: widget.event.description);

    // Parse and set the date if available
    if (widget.event.date.isNotEmpty) {
      try {
        selectedEventDate = DateFormat('yyyy-MM-dd').parse(widget.event.date);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Parse and set the time if available
    if (widget.event.time.isNotEmpty) {
      try {
        // Parse time from string like "9:30 PM"
        selectedEventTime = _parseTimeFromString(widget.event.time);
        eventTimeController = TextEditingController(text: widget.event.time);
      } catch (e) {
        print('Error parsing time: $e');
        eventTimeController = TextEditingController();
      }
    } else {
      eventTimeController = TextEditingController();
    }

    // Parse and set event type
    selectedEventType = widget.event.type.toLowerCase();
    eventTypeController = TextEditingController(text: widget.event.type);

    // Parse and set ticket limit
    eventTicketLimitController = TextEditingController(
        text: widget.event.ticketLimit.toString()
    );

    // Parse and set amount if paid event
    if (widget.event.type.toLowerCase() == 'paid') {
      // Remove currency symbol if present
      final amountText = widget.event.amount.toString().replaceAll(RegExp(r'[^\d.]'), '');
      eventAmountController = TextEditingController(text: amountText);
    } else {
      eventAmountController = TextEditingController();
    }

    // Set image URL if available
    if (widget.event.image.isNotEmpty) {
      uploadedImageUrl = widget.event.image;
    }
  }

  // Helper method to parse time string like "9:30 PM" to TimeOfDay
  TimeOfDay? _parseTimeFromString(String timeString) {
    try {
      // Handle formats like "9:30 PM" or "14:30"
      final timeParts = timeString.split(' ');
      final timeValue = timeParts[0];
      final period = timeParts.length > 1 ? timeParts[1] : null;

      final hourMinute = timeValue.split(':');
      if (hourMinute.length != 2) return null;

      int hour = int.parse(hourMinute[0]);
      int minute = int.parse(hourMinute[1]);

      // Adjust hour for PM if needed
      if (period?.toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (period?.toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('Error parsing time string: $e');
      return null;
    }
  }

  @override
  void dispose() {
    eventTitleController.dispose();
    eventTimeController.dispose();
    eventLocationController.dispose();
    eventDescriptionController.dispose();
    eventTicketLimitController.dispose();
    eventAmountController.dispose();
    eventTypeController.dispose();
    super.dispose();
  }

  // ===================== TIME PICKER =====================
  Future<void> _pickEventTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedEventTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedEventTime = picked;
        // Format time in 12-hour format (e.g., "9:30 PM")
        eventTimeController.text = _formatTime12Hour(picked);
      });
    }
  }

  // Helper method to format TimeOfDay to 12-hour format
  String _formatTime12Hour(TimeOfDay time) {
    final hour = time.hourOfPeriod; // This gives 0-11
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    // Handle special case for 0 hour (12 AM/PM)
    final displayHour = hour == 0 ? 12 : hour;

    return '$displayHour:$minute $period';
  }

  // ===================== IMAGE UPLOAD =====================
  Future<void> _uploadEventImage() async {
    final imageFile = eventImageNotifier.value;

    // If no new image selected but we have existing image URL, use that
    if (imageFile == null && uploadedImageUrl != null) {
      return; // Keep existing image
    }

    if (imageFile == null) {
      throw Exception('Event image is required');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path),
      'upload_preset': 'soundhive',
    });

    final response = await Dio().post(
      'https://api.cloudinary.com/v1_1/djutcezwz/image/upload',
      data: formData,
    );

    if (response.statusCode != 200) {
      throw Exception('Image upload failed');
    }

    uploadedImageUrl = response.data['secure_url'];
  }

  // ===================== VALIDATION =====================
  bool _validateForm() {
    if (eventTitleController.text.trim().isEmpty) {
      _showError('Please enter event title');
      return false;
    }

    if (selectedEventDate == null) {
      _showError('Please select event date');
      return false;
    }

    if (selectedEventTime == null) {
      _showError('Please select event time');
      return false;
    }

    if (eventLocationController.text.trim().isEmpty) {
      _showError('Please enter event location');
      return false;
    }

    if (eventDescriptionController.text.trim().isEmpty) {
      _showError('Please enter event description');
      return false;
    }

    if (selectedEventType == null) {
      _showError('Please select event type');
      return false;
    }

    if (selectedEventType == 'paid') {
      if (eventAmountController.text.trim().isEmpty) {
        _showError('Please enter ticket amount');
        return false;
      }
    }

    // Only require new image if no existing image URL
    if (eventImageNotifier.value == null && uploadedImageUrl == null) {
      _showError('Please upload event image');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: message,
    );
  }

  // ===================== SUBMIT =====================
  Future<void> _submitEvent() async {
    if (!_validateForm()) return;

    try {
      LoaderService.showLoader(context);

      // Only upload if new image was selected
      if (eventImageNotifier.value != null) {
        await _uploadEventImage();
      }

      final formattedTime = _formatTime12Hour(selectedEventTime!);

      final payload = {
        "title": eventTitleController.text.trim(),
        "date": DateFormat('yyyy-MM-dd').format(selectedEventDate!),
        "time": formattedTime,
        "location": eventLocationController.text.trim(),
        "description": eventDescriptionController.text.trim(),
        "type": selectedEventType?.toUpperCase(),
        "ticket_limit": eventTicketLimitController.text.isEmpty
            ? 0
            : int.parse(eventTicketLimitController.text),
        "amount": selectedEventType == 'paid'
            ? double.parse(eventAmountController.text.replaceAll(",", ""))
            : 0,
        "image": uploadedImageUrl,
      };

      // Use update event API instead of create event
      final response =
      await ref.read(apiresponseProvider.notifier).updateEvent(
        context: context,
        eventId: widget.event.id, // Pass the event ID
        payload: payload,
      );

      if (!response.status) {
        throw Exception(response.message);
      }
      if (!mounted) return;

      LoaderService.hideLoader(context);
      await ref.read(eventStatsProvider.notifier).getStats();
      // Invalidate providers to refresh data
      ref.invalidate(eventProvider('published'));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Event Updated Successfully',
            subtitle: 'Your event has been updated',
            onButtonPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const EventScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      LoaderService.hideLoader(context);
      _showError(e.toString());
    }
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Event', // Changed from 'Create New Event'
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 30),

                  LabeledTextField(
                    label: 'Title',
                    controller: eventTitleController,
                    hintText: 'Event title',
                  ),

                  const SizedBox(height: 12),
                  const Text('Event Date',
                     ),
                  const SizedBox(height: 6),

                  SingleDateSelectionInput(
                    initialSelectedDate: selectedEventDate,
                    onDateSelected: (date) {
                      setState(() {
                        selectedEventDate = date;
                      });
                    },
                  ),

                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickEventTime,
                    child: AbsorbPointer(
                      child: LabeledTextField(
                        label: 'Time',
                        controller: eventTimeController,
                        hintText: 'Select time',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  LabeledTextField(
                    label: 'Location',
                    controller: eventLocationController,
                    hintText: 'Event location',
                  ),

                  const SizedBox(height: 12),
                  LabeledTextField(
                    label: 'Description',
                    controller: eventDescriptionController,
                    maxLines: 4,
                    hintText: 'Event description',
                  ),

                  const SizedBox(height: 12),
                  LabeledSelectField(
                    label: 'Event Type',
                    controller: eventTypeController,
                    items: eventTypeOptions,
                    hintText: 'Select event type',
                    onChanged: (value) {
                      setState(() {
                        selectedEventType = value;
                      });
                    },
                  ),

                  if (selectedEventType == 'paid') ...[
                    const SizedBox(height: 12),
                    CurrencyInputField(
                      label: "Amount",
                      controller: eventAmountController,
                      onChanged: (value) {
                        print('Input changed to: $value');
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty || double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  LabeledTextField(
                    label: 'Ticket Limit (Optional)',
                    controller: eventTicketLimitController,
                    keyboardType: TextInputType.number,
                    hintText: 'Enter ticket limit',
                  ),

                  const SizedBox(height: 12),
                  ImagePickerComponent(
                    labelText: 'Event Image',
                    imageNotifier: eventImageNotifier,
                    hintText: 'Upload image',
                    initialImageUrl: uploadedImageUrl, // Pass existing image URL
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: RoundedButton(
                title: 'Update Event', // Changed from 'Create Event'
                onPressed: _submitEvent,
                color: AppColors.PRIMARYCOLOR,
                borderWidth: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

