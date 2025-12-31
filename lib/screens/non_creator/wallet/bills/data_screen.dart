import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/non_creator/wallet/bills/pin_input_sheet.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/variation_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../../model/apiresponse_model.dart';
import '../../../../model/user_model.dart';
import 'bill_confirmation_screen.dart';

class DataScreen extends ConsumerStatefulWidget {
  final User user;
  const DataScreen({super.key, required this.user});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String? selectedNetwork;
  String? selectedVariation;
  String formatVariationName(String? raw) {
    if (raw == null || raw.isEmpty) return "";

    return raw
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) {
      if (word.toLowerCase().contains('mb') ||
          word.toLowerCase().contains('gb')) {
        return word.toUpperCase();
      }
      return word[0].toUpperCase() + word.substring(1);
    })
        .join(' ');
  }

  final List<int> quickAmounts = [100, 200, 500, 1000, 2000, 5000];
  void showPinInputDialog({
    required BuildContext context,
    required Function(String pin) onCompleted,
    int pinLength = 4,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return PinInputSheet(
          pinLength: pinLength,
          onCompleted: onCompleted,
        );
      },
    );
  }

  void _payBill(String pin) async {
    try {
      final payload = {
        "amount": amountController.text,
        'serviceID': "${selectedNetwork?.toLowerCase()}-data",
        'phone_number': phoneController.text,
        'pin': pin,
        "variation_code": selectedVariation
      };

      final response = await ref.read(apiresponseProvider.notifier).buyData(
        context: context,
        payload: payload,
      );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Transaction Successful',
              subtitle: "${formatVariationName(selectedVariation)} data successfully sent to ${phoneController.text}",
              onButtonPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } catch (error) {
      _handleOfferError(error);
    }
  }

  void _handleOfferError(dynamic error) {
    String errorMessage = 'An unexpected error occurred';

    print("Raw error: $error");

    if (error is DioException) {
      print("Dio error: ${error.response?.data}");
      print("Status code: ${error.response?.statusCode}");

      if (error.response?.data != null) {
        try {
          final apiResponse = ApiResponseModel.fromJson(error.response?.data);
          errorMessage = apiResponse.message;
        } catch (e) {
          errorMessage = 'Failed to parse error message';
        }
      } else {
        errorMessage = error.message ?? 'Network error occurred';
      }
    }

    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: errorMessage,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery
                            .of(context)
                            .viewInsets
                            .bottom + 20,
                      ),
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _header(context),
                                const SizedBox(height: 32),

                                _label("Phone number"),
                                _inputField(
                                  controller: phoneController,
                                  hint: "Enter your phone number",
                                  keyboardType: TextInputType.phone,
                                ),

                                const SizedBox(height: 24),

                                _label("Network"),
                                _dropdownField(),

                                const SizedBox(height: 24),
                                _label("Package"),
                                _dropdownPackageField(),
                                const SizedBox(height: 24),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    _label("Amount"),
                                    Text(
                                      "Balance: ${ref.formatUserCurrency(
                                          widget.user.wallet?.balance)}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                _inputField(
                                  controller: amountController,
                                  hint: "Enter amount",
                                  keyboardType: TextInputType.number,
                                  isReadOnly: true
                                ),
                                const Spacer(),
                                RoundedButton(
                                    title: 'Continue',
                                    onPressed: () {
                                      if (phoneController.text.isEmpty ||
                                          selectedNetwork!.isEmpty ||
                                          amountController.text.isEmpty) {
                                        return showCustomAlert(context: context,
                                            isSuccess: false,
                                            title: "Error",
                                            message: "Please complete all fields");
                                      }
                                     

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                BillConfirmationScreen(
                                                  title: "Confirm Transaction",
                                                  amount: amountController.text,
                                                  items: [
                                                    ConfirmationItem(
                                                        label: "Network:",
                                                        value: selectedNetwork ??
                                                            ''),
                                                    ConfirmationItem(
                                                        label: "Phone number:",
                                                        value: phoneController
                                                            .text),
                                                    ConfirmationItem(
                                                        label: "Package",
                                                        value: formatVariationName(selectedVariation ?? "")),
                                                    ConfirmationItem(
                                                        label: "Transaction fee:",
                                                        value: "₦0.00"),
                                                    ConfirmationItem(
                                                        label: "Description:",
                                                        value: "Data"),
                                                  ],
                                                  onPinTap: () {
                                                    showPinInputDialog(
                                                      context: context,
                                                      onCompleted: (pin) {
                                                        debugPrint(
                                                            "PIN entered: $pin");
                                                        _payBill(pin);
                                                      },
                                                    );
                                                  },
                                                  onBiometricTap: () {
                                                    // trigger fingerprint auth
                                                  },
                                                )
                                        ),
                                      );
                                    }
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          )
                      )
                  );
                },
              ),
            )
        )
    );
  }

  // ---------------- WIDGETS ----------------

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF656566)),
          onPressed: () => Navigator.pop(context),
        ),
        Container(
          alignment: Alignment.center,
          child: const Text(
            "Data",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    isReadOnly = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF141019),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: isReadOnly,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownField() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF141019),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF141019),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          value: selectedNetwork,
          hint: const Text(
            "Select network",
            style: TextStyle(color: Colors.white38),
          ),
          style: const TextStyle(color: Colors.white),
          items: ["MTN", "Glo", "Airtel", "9mobile"]
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() => selectedNetwork = value);
            ref.read(variationProvider.notifier).loadServiceVariation("${selectedNetwork?.toLowerCase()}-data");
          },
        ),
      ),
    );
  }
  Widget _dropdownPackageField() {
    final serviceVariations = ref.watch(variationProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF141019),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: serviceVariations.when(
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error loading',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (variations) {
          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF141019),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white54,
              ),
              value: selectedVariation,
              hint: const Text(
                "Select Variation",
                style: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
              items: variations.map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem<String>(
                  value: v.variationCode,
                  child: Text(v.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedVariation = value;

                  final selected = variations.firstWhere(
                        (v) => v.variationCode == value,
                    orElse: () => variations.first,
                  );

                  amountController.text = selected.variationAmount.toString();
                });
              },

            ),
          );
        },
      ),
    );
  }

}
