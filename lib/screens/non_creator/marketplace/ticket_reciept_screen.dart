import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:soundhive2/screens/non_creator/marketplace/ticket_detail_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../model/ticket_model.dart';

class TicketReceiptScreen extends ConsumerStatefulWidget {
  final TicketItem ticket;

  const TicketReceiptScreen({
    super.key,
    required this.ticket,
  });

  @override
  ConsumerState<TicketReceiptScreen> createState() =>
      _TicketReceiptScreenState();
}

class _TicketReceiptScreenState
    extends ConsumerState<TicketReceiptScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isDownloading = false;

  // Method to navigate to TicketDetailScreen
  void _navigateToTicketDetail() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(
          ticket: widget.ticket,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.ticket.event;

    // Extract base64 data from qr_code_path
    String qrCodeData = widget.ticket.qrCodePath;

    // If it's a base64 string, decode it
    Uint8List? qrCodeBytes;
    if (qrCodeData.startsWith('data:image/png;base64,')) {
      try {
        String base64Image = qrCodeData.split(',').last;
        qrCodeBytes = base64.decode(base64Image);
      } catch (e) {
        print('Error decoding base64 QR: $e');
      }
    }

    return PopScope(
      canPop: false, // Disable default back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _navigateToTicketDetail();
        }
      },
      child: Scaffold(
       
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0C0014),
                Color(0xFF1A002A),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                /// Back Button
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketDetailScreen(
                              ticket: widget.ticket,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                /// Ticket Card
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A191E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Event Logo/Header
                            Align(
                              child: Column(
                                children: [
                                  Text(
                                    widget.ticket.ticketNumber,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// Event Title
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// Date & Time
                            Row(
                              children: [
                               const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "${event.date}",
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  event.time,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            /// Location
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            _dashedDivider(),
                            const SizedBox(height: 24),

                            /// QR Code
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white30,
                                    width: 1,
                                  ),
                                ),
                                child: qrCodeBytes != null
                                    ? Image.memory(
                                  qrCodeBytes,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                )
                                    : PrettyQrView.data(
                                  data: widget.ticket.ticketNumber,
                                  errorCorrectLevel:
                                  QrErrorCorrectLevel.H,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// Scan Instruction
                            const Center(
                              child: Text(
                                "Scan QR code at entrance",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            _dashedDivider(),
                            const SizedBox(height: 20),

                            /// Ticket Details Section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  /// Attendee & Ticket Price
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      _infoColumn(
                                        title: "Attendee",
                                        value: "${widget.ticket.user.firstName} ${widget.ticket.user.lastName}",
                                      ),
                                      _infoColumn(
                                        title: "Ticket Price",
                                        value:
                                        ref.formatUserCurrency(widget.ticket.amount),
                                        alignEnd: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                /// Download Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _downloadTicket,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B51E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isDownloading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Download ticket",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadTicket() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // For Android 13+ and iOS, we don't need storage permission for temporary directory
      // But we might need photos permission if user wants to save to gallery

      // Capture screenshot
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0, // High quality
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes == null) {
        throw Exception('Failed to capture screenshot');
      }

      // Get directory for saving - getTemporaryDirectory() doesn't need permission
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ticket_${widget.ticket.ticketNumber}_$timestamp.png';
      final filePath = '${directory.path}/$fileName';

      // Save image to temporary directory - no permission needed
      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(imageBytes);

      // Create XFile for sharing
      final xFile = XFile(filePath);

      // Create ShareParams with the new API
      final params = ShareParams(
        text: 'My ticket for ${widget.ticket.event.title}\n\n'
            'Ticket Number: ${widget.ticket.ticketNumber}\n'
            'Event: ${widget.ticket.event.title}\n'
            'Date: ${widget.ticket.event.date}\n'
            'Time: ${widget.ticket.event.time}\n'
            'Location: ${widget.ticket.event.location}',
        subject: 'Ticket - ${widget.ticket.event.title}',
        files: [xFile],
        sharePositionOrigin: Rect.fromPoints(
          Offset.zero,
          Offset(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2),
        ),
      );

      // Share the ticket using the new API
      final result = await SharePlus.instance.share(params);

      // Check result if needed
      if (result.status == ShareResultStatus.success) {
        _showSnackBar('Ticket saved successfully!', isError: false);
      } else if (result.status == ShareResultStatus.dismissed) {
        _showSnackBar('Share cancelled', isError: false);
      }

    } catch (e) {
      print('Error downloading ticket: $e');
      _showSnackBar('Failed to download ticket: $e');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }


  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dashed divider
  Widget _dashedDivider() {
    return Row(
      children: List.generate(
        30,
            (index) => Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: Colors.white12,
          ),
        ),
      ),
    );
  }

  Widget _infoColumn({
    required String title,
    required String value,
    bool alignEnd = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}