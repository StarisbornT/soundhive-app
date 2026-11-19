import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../components/success.dart';
import '../../../lib/dashboard_provider/apiresponseprovider.dart';

/// Change the 4-digit transaction PIN: current PIN → new PIN → confirm.
/// Uses POST /pin/change, which checks the current PIN on the server.
/// If the account has no PIN yet (server answers code NO_PIN), the new PIN is set with /create/pin.
class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

enum _Step { current, newPin, confirm }

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  _Step _step = _Step.current;
  String _current = '';
  String _newPin = '';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _title {
    switch (_step) {
      case _Step.current:
        return 'Enter current PIN';
      case _Step.newPin:
        return 'Enter new PIN';
      case _Step.confirm:
        return 'Confirm new PIN';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _Step.current:
        return 'Enter the 4-digit PIN you use to confirm payments.';
      case _Step.newPin:
        return 'Choose a new 4-digit PIN.';
      case _Step.confirm:
        return 'Enter your new PIN again.';
    }
  }

  void _goTo(_Step step, {String? error}) {
    setState(() {
      _step = step;
      _error = error;
    });
    _controller.clear();
    _focus.requestFocus();
  }

  Future<void> _onCompleted(String value) async {
    if (_busy) return;
    switch (_step) {
      case _Step.current:
        _current = value;
        _goTo(_Step.newPin);
        break;
      case _Step.newPin:
        if (value == _current) {
          _goTo(_Step.newPin, error: 'Your new PIN must be different from your current PIN.');
          return;
        }
        _newPin = value;
        _goTo(_Step.confirm);
        break;
      case _Step.confirm:
        if (value != _newPin) {
          _goTo(_Step.newPin, error: "The PINs didn't match. Enter your new PIN again.");
          return;
        }
        await _submit();
        break;
    }
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = ref.read(apiresponseProvider.notifier);
    try {
      try {
        await api.changePin(currentPin: _current, pin: _newPin);
      } on DioException catch (e) {
        final data = e.response?.data;
        // The account has no PIN yet: set this one as the first PIN.
        if (data is Map && data['code'] == 'NO_PIN') {
          await api.createPin(context: context, pin: _newPin);
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Success(
            image: 'images/success_profile.png',
            title: 'PIN Changed Successfully',
            subtitle: 'Use your new PIN to confirm payments from now on.',
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : 'Could not change your PIN. Check your connection and try again.';
      setState(() => _busy = false);
      if (status == 422 && data is Map && data['errors'] is Map && (data['errors'] as Map).containsKey('current_pin')) {
        _goTo(_Step.current, error: message); // wrong current PIN: start again
      } else if (status == 429) {
        _goTo(_Step.current, error: message); // locked for a while
      } else {
        _goTo(_Step.newPin, error: message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      _goTo(_Step.current, error: 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : Colors.black87;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final stepIndex = _Step.values.indexOf(_step);

    final pinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (_busy) return;
            if (_step == _Step.current) {
              Navigator.pop(context);
            } else {
              _goTo(_Step.values[stepIndex - 1]);
            }
          },
        ),
        title: const Text('Change PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Progress: 3 short bars
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= stepIndex ? const Color(0xFF4D3490) : borderColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF4D3490).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_outline, size: 30, color: Color(0xFF8C6CE0)),
              ),
              const SizedBox(height: 20),
              Text(_title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 8),
              Text(_subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 32),
              Pinput(
                key: ValueKey(_step), // fresh field for each step
                length: 4,
                controller: _controller,
                focusNode: _focus,
                autofocus: true,
                obscureText: true,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                defaultPinTheme: pinTheme,
                focusedPinTheme: pinTheme.copyWith(
                  decoration: pinTheme.decoration!.copyWith(border: Border.all(color: const Color(0xFF8C6CE0), width: 2)),
                ),
                onCompleted: _onCompleted,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
              if (_busy) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: Color(0xFF8C6CE0)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
