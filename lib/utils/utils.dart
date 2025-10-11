import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../model/user_model.dart';
import 'app_colors.dart';

extension UserCurrencyExtension on WidgetRef {



  String get userCurrency {
    final userState = read(userProvider);
    return userState.value?.user?.wallet?.currency ?? "USD";
  }
  String get creatorBaseCurrency {
    final userState = read(userProvider);
    return userState.value?.user?.creator?.baseCurrency ?? "USD";
  }

  String formatUserCurrency(dynamic amount) {
    final currencyCode = userCurrency;
    return Utils.formatCurrency(amount, currencyCode: currencyCode);
  }
  String formatCreatorCurrency(dynamic amount) {
    final currencyCode = creatorBaseCurrency;
    return Utils.formatCurrency(amount, currencyCode: currencyCode);
  }

  String get userCurrencySymbol {
    final currencyCode = userCurrency;
    return Utils.getCurrencySymbol(currencyCode);
  }
  String get creatorCurrencySymbol {
    final currencyCode = creatorBaseCurrency;
    return Utils.getCurrencySymbol(currencyCode);
  }
}

class Utils {
  static String formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toString();
    }
  }
  static String formatCurrency(dynamic amount, {String? currencyCode}) {
    currencyCode ??= "USD";

    final double numericAmount = double.tryParse(amount.toString()) ?? 0.0;

    final formatter = NumberFormat.currency(
      locale: "en_US",
      symbol: "",
      decimalDigits: 2,
      name: currencyCode,
    );

    return "$currencyCode ${formatter.format(numericAmount)}";
  }

  static String getCurrencySymbol(String? currencyCode) {
    currencyCode ??= "USD";
    return currencyCode;
  }


  static Widget menuButton(String text, bool selected, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.PRIMARYCOLOR : AppColors.DARKGREY,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
            color: Colors.white,
          fontSize: 12
        )),
      ),
    );
  }


  static Widget logo() {
    return  Image.asset('images/logo.png', width: 200);
  }

  static Widget reviewCard(
      BuildContext context, {
        String? title,
        String? subtitle,
        String? image,
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        }
      },
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF524671),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible( // or Expanded
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Account under review',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle ?? "We are currently reviewing your \n submissions, and will give \n feedback within 24hours.",
                    style: const TextStyle(
                      color: Color(0xFFB0B0B6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              image ?? 'images/review.png',
              width: 100,
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
  static Widget adsBanner(BuildContext context) {
    return Container(
      width: 450,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF524671),
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('images/ads.png'),
          alignment: Alignment.topRight,
          fit: BoxFit.none, // Prevent stretch
          scale:  3,       // Adjust size of the image
          opacity: 0.9,     // Optional: make it subtle
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover amazing music talents',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white
            ),
          ),
          Text(
            "Explore the best of new music and \n discover talented artists that'll \n keep you grooving.",
            style: TextStyle(
                color: Color(0xFFB0B0B6),
                fontSize: 12
            ),
          ),
        ],
      ),
    );
  }
 static Widget buildImagePlaceholder() {
    return Container(
      height: 150,
      color: Colors.grey[800],
      child: Icon(Icons.broken_image, color: Colors.white54),
    );
  }
 static Widget buildCreativeCard(
      BuildContext context, {
        required String name,
        required String role,
        required double rating,
        required String profileImage,
        required String firstName,
      }) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(left: 16.0, right: 8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          profileImage.isNotEmpty
              ? Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(profileImage),
                fit: BoxFit.cover,
              ),
            ),
          )
              : Container(
            width: 120,
            height: 120,
            decoration:  const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.BUTTONCOLOR, // Fallback background color
            ),
            alignment: Alignment.center,
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : "?",
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            role,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              Text(
                '$rating rating',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  static Widget confirmRow(String title, dynamic value) {
    Color? backgroundColor;
    Color textColor = Colors.black;
    Widget displayWidget;

    // Handle String case (original functionality)
    if (value is String) {
      String displayValue = value;

      if (title == 'Status') {
        switch (value.toUpperCase()) {
          case 'PENDING':
            backgroundColor = const Color(0x1AFFC107);
            textColor = const Color(0xFFFFC107);
            displayValue = 'Under review';
            break;
          case 'rejected':
            backgroundColor = const Color(0x1AFE6161);
            textColor = const Color(0xFFFE6163);
            displayValue = 'Rejected';
            break;
          case 'Pusblished':
            backgroundColor = const Color(0x1A4CAF50);
            textColor = const Color(0xFF4CAF50);
            displayValue = 'Published';
            break;
          default:
            backgroundColor = Colors.grey;
            displayValue = value;
        }
      }

      displayWidget = title == 'Status'
          ? Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          displayValue,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      )
          : Flexible(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
              fontFamily: 'Roboto'
          ),

          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    // Handle List case (for availableToWork)
    else if (value is List) {
      displayWidget = Flexible(
        child: Text(
          value.join(', '),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    // Handle other cases
    else {
      displayWidget = Text(
        value.toString(),
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: Color(0xFFB0B0B6))),
          displayWidget,
        ],
      ),
    );
  }
  static void showBankTransferBottomSheet(BuildContext context, String? bankName, String? accountNumber, String? accountName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Add via Bank Transfer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
              ),
              SizedBox(height: 8),

              // Instructional text
              const Text(
                'Kindly make a transfer of your desired amount to your unique account number below',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 16),

              // Bank Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Bank', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              SizedBox(height: 4),

              // Bank Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  bankName ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
                ),
              ),
              SizedBox(height: 16),

              // Account Number Label
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Account number', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              SizedBox(height: 4),

              // Account Number with Copy Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    accountNumber ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: accountNumber ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Account number copied!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Account Name', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              SizedBox(height: 4),

              // Bank Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  accountName ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: Colors.white),
                ),
              ),

              SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.BUTTONCOLOR,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Okay, thanks',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Helper widget to build the other information card
  static Widget buildOtherInfoCard({
    required MemberCreatorResponse user,
    required Color cardBackgroundColor,
    required Color textColor,
    required Color hintTextColor,
    bool showTitle = true
  }) {
    final bvn = user.user?.bvn;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(showTitle)
          Text(
            'Other Information',
            style: TextStyle(
              color: hintTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Phone number', user.user?.phoneNumber ?? 'Not specified', textColor, hintTextColor),
          _buildInfoRow(
              'Email address', user.user?.email ?? 'Not specified', textColor, hintTextColor),
          _buildInfoRow(
              'Gender', user.user?.gender?.capitalize() ?? 'Not specified', textColor, hintTextColor),
          _buildInfoRow(
              'Date of Birth', user.user?.dob ?? 'Not specified', textColor, hintTextColor),
          _buildInfoRow(
            'BVN',
            bvn != null && bvn.length >= 4
                ? '********${bvn.substring(bvn.length - 4)}'
                : 'Not specified',
            textColor,
            hintTextColor,
          ),
          _buildInfoRow(
              'NIN', user.user?.creator?.nin ?? 'Not specified', textColor, hintTextColor),
        ],
      ),
    );
  }




  // Helper for consistent info rows in "Other Information"
  static Widget _buildInfoRow(
      String label, String value, Color textColor, Color hintTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: hintTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }


}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
