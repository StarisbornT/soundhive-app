import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/utils/utils.dart';

class BillConfirmationScreen extends ConsumerWidget {
  final String title;
  final String amount;
  final List<ConfirmationItem> items;
  final VoidCallback? onBack;
  final VoidCallback? onPinTap;
  final VoidCallback? onBiometricTap;

  const BillConfirmationScreen({
    super.key,
    required this.title,
    required this.amount,
    required this.items,
    this.onBack,
    this.onPinTap,
    this.onBiometricTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C0717),
              Color(0xFF05010D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 24),

              _amountSection(ref),
              const SizedBox(height: 24),

              _detailsCard(),
              const SizedBox(height: 28),

              _pinSection(),
              const SizedBox(height: 40),

              _biometricIcon(),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI PARTS ----------------

  Widget _header(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: onBack ?? () => Navigator.pop(context),
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _amountSection(WidgetRef ref) {
    return Column(
      children: [
        const Text(
          "You are paying",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ref.formatUserCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _detailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1722),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _detailRow(item.label, item.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _pinSection() {
    return GestureDetector(
      onTap: onPinTap,
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: Colors.green, size: 16),
              SizedBox(width: 6),
              Text(
                "Tap to input transaction PIN",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1722),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                4,
                    (_) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _biometricIcon() {
    return GestureDetector(
      onTap: onBiometricTap,
      child: const Icon(
        Icons.fingerprint,
        color: Color(0xFFB68CFF),
        size: 64,
      ),
    );
  }
}

class ConfirmationItem {
  final String label;
  final String value;

  ConfirmationItem({
    required this.label,
    required this.value,
  });
}
