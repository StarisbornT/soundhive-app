import 'package:flutter/material.dart';

class PinInputSheet extends StatefulWidget {
  final int pinLength;
  final Function(String pin) onCompleted;

  const PinInputSheet({super.key,
    required this.pinLength,
    required this.onCompleted,
  });

  @override
  State<PinInputSheet> createState() => _PinInputSheetState();
}

class _PinInputSheetState extends State<PinInputSheet> {
  String pin = "";

  void _addDigit(String digit) {
    if (pin.length < widget.pinLength) {
      setState(() => pin += digit);

      if (pin.length == widget.pinLength) {
        Navigator.pop(context);
        widget.onCompleted(pin);
      }
    }
  }

  void _removeDigit() {
    if (pin.isNotEmpty) {
      setState(() => pin = pin.substring(0, pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0717),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Enter Transaction PIN",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          _pinDots(),
          const SizedBox(height: 24),

          _numberPad(),
        ],
      ),
    );
  }

  Widget _pinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.pinLength,
            (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < pin.length
                ? Colors.white
                : Colors.white24,
          ),
        ),
      ),
    );
  }

  Widget _numberPad() {
    final numbers = [
      "1", "2", "3",
      "4", "5", "6",
      "7", "8", "9",
      "", "0", "⌫",
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: numbers.length,
      itemBuilder: (_, index) {
        final value = numbers[index];

        if (value.isEmpty) return const SizedBox();

        return GestureDetector(
          onTap: () {
            if (value == "⌫") {
              _removeDigit();
            } else {
              _addDigit(value);
            }
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1722),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}
