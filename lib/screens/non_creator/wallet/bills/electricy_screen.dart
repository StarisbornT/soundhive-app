import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/non_creator/wallet/bills/pin_input_sheet.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/identifiers.dart';
import '../../../../lib/dashboard_provider/verify_merchant_provider.dart';
import '../../../../model/apiresponse_model.dart';
import '../../../../model/user_model.dart';
import '../../../../model/verify_merchant_model.dart';
import 'bill_confirmation_screen.dart';

class ElectricityScreen extends ConsumerStatefulWidget {
  final User user;
  const ElectricityScreen({super.key, required this.user});

  @override
  ConsumerState<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends ConsumerState<ElectricityScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController meterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(identifierProvider.notifier).loadIdentifier('electricity-bill');
    });
  }

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
        'serviceID': "${selectedVariation?.toLowerCase()}",
        'phone_number': widget.user.phoneNumber,
        'billerCode': meterController.text,
        'pin': pin,
        "variation_code": selectedNetwork
      };

      final response = await ref.read(apiresponseProvider.notifier).buyElectricity(
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
              subtitle: "You have successfully bought electricity token worth ₦${amountController.text}",
              token: response.data['token'] ?? "", // Pass the token here
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
  String customerName = "";
  String arrears = "";
  void _triggerVerifyMerchant() {
    if (selectedVariation!.isNotEmpty &&
        meterController.text.length == 13 &&
        selectedNetwork!.isNotEmpty) {
      verifyMerchant();
    }
  }
  void verifyMerchant() async {
    try {
      final response = await ref.read(verifyMerchantProvider.notifier).verifyMerchant(
          serviceId: selectedVariation ?? "",
          billersCode: meterController.text,
          type: selectedNetwork?.toLowerCase()
      );
      if(response.success) {
        setState(() {
          customerName = response.data.customerName;
          arrears = response.data.customerArrears;
        });
      }

    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = VerifyMerchantResponse.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      print("Error: $errorMessage");

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
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

                                _label("Service Provider"),
                                _dropdownPackageField(),

                                const SizedBox(height: 24),
                                _label("Meter Number"),
                                _inputField(
                                  controller: meterController,
                                  hint: "Enter meter number",
                                  keyboardType: TextInputType.number,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      customerName,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.green
                                      ),
                                    ),

                                    Text(
                                      arrears,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Colors.green
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _label("Package"),
                                _dropdownField(),

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
                                ),
                                const Spacer(),
                                RoundedButton(
                                    title: 'Continue',
                                    onPressed: () {
                                      if (meterController.text.isEmpty ||
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
                                                        label: "Service Provider:",
                                                        value: formatVariationName(selectedVariation ?? "")),
                                                    ConfirmationItem(
                                                        label: "Meter number:",
                                                        value: meterController
                                                            .text),
                                                    ConfirmationItem(
                                                        label: "Package",
                                                        value: selectedNetwork ?? ""),
                                                    ConfirmationItem(
                                                        label: "Transaction fee:",
                                                        value: "₦0.00"),
                                                    ConfirmationItem(
                                                        label: "Description:",
                                                        value: "Electricity"),
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
            "Electricity",
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
          items: ["Prepaid", "Postpaid"]
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() => selectedNetwork = value);
            _triggerVerifyMerchant();
          },
        ),
      ),
    );
  }
  Widget _dropdownPackageField() {
    final identifiers = ref.watch(identifierProvider);

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
      child: identifiers.when(
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, _) => const Center(
          child: Text(
            'Error loading',
            style: TextStyle(color: Colors.redAccent),
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
                  value: v.serviceId,
                  child: Text(v.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedVariation = value;
                  _triggerVerifyMerchant();
                });
              },

            ),
          );
        },
      ),
    );
  }

}
