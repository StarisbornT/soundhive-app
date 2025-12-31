import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/eventProvider.dart';
import 'package:soundhive2/screens/creator/events/event_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/image_picker.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../components/widgets.dart';
import '../../../lib/dashboard_provider/event_stats_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/user_model.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';
import '../creator_dashboard.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
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

    eventTitleController = TextEditingController();
    eventTimeController = TextEditingController();
    eventLocationController = TextEditingController();
    eventDescriptionController = TextEditingController();
    eventTicketLimitController = TextEditingController();
    eventAmountController = TextEditingController();
    eventTypeController = TextEditingController();
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

    if (eventImageNotifier.value == null) {
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

      await _uploadEventImage();

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
            ? double.parse(eventAmountController.text)
            : 0,
        "image": uploadedImageUrl,
      };

      final response =
      await ref.read(apiresponseProvider.notifier).createEvent(
        context: context,
        payload: payload,
      );

      if (!response.status) {
        throw Exception(response.message);
      }
      if (!mounted) return;

      LoaderService.hideLoader(context);
      await ref.read(eventStatsProvider.notifier).getStats();
      ref.watch(eventProvider('published'));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Event Created Successfully',
            subtitle: 'Your event has been published',
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
                    'Create New Event',
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
                      selectedEventDate = date;
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
                      selectedEventType = value;
                      setState(() {});
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
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: RoundedButton(
                title: 'Create Event',
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

