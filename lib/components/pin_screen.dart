import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class PinAuthenticationScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final int pinLength;
  final String buttonName;
  final Function(String) onPinEntered;

  const PinAuthenticationScreen({
    Key? key,
    this.title = "Authentication PIN",
    this.subtitle = "Kindly enter your 4-digit authentication PIN",
    this.pinLength = 4,
    required this.onPinEntered,
    required this.buttonName,
  }) : super(key: key);

  @override
  _PinAuthenticationScreenState createState() =>
      _PinAuthenticationScreenState();
}

class _PinAuthenticationScreenState extends State<PinAuthenticationScreen> {
  String _enteredPin = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              alignment: Alignment.center,
              child: Text(
                widget.subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            Pinput(
              length: widget.pinLength,
              onChanged: (pin) => setState(() => _enteredPin = pin),
              obscureText: true,
              defaultPinTheme: PinTheme(
                width: 50,
                height: 50,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D3490),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _enteredPin.length == widget.pinLength
                    ? () => widget.onPinEntered(_enteredPin)
                    : null,
                child: Text(widget.buttonName, style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
