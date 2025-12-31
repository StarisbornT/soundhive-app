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
import 'package:soundhive2/lib/dashboard_provider/verify_merchant_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/variation_provider.dart';
import '../../../../model/apiresponse_model.dart';
import '../../../../model/identifier_model.dart';
import '../../../../model/user_model.dart';
import '../../../../model/verify_merchant_model.dart';
import 'bill_confirmation_screen.dart';

class CableTvScreen extends ConsumerStatefulWidget {
  final User user;
  const CableTvScreen({super.key, required this.user});

  @override
  ConsumerState<CableTvScreen> createState() => _CableTvScreenState();
}

class _CableTvScreenState extends ConsumerState<CableTvScreen> {
  final TextEditingController _smartCardNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentTypeController = TextEditingController();

  String? selectedPlan;
  String? tvPlan;
  String customerName = "";
  String arrears = "";

  final List<String> category = ["Change", "Renew"];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(identifierProvider.notifier).loadIdentifier('tv-subscription');
    });
  }

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
        "amount": _amountController.text,
        'serviceID': selectedPlan ?? "",
        'phone_number': widget.user.phoneNumber,
        'billerCode': _smartCardNumberController.text,
        'pin': pin,
        "variation_code": tvPlan,
        "type": _paymentTypeController.text.toLowerCase(),
        "quantity": "1"
      };

      final response = await ref.read(apiresponseProvider.notifier).payCable(
        context: context,
        payload: payload,
      );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Payment Made Successfully',
              subtitle: "You have successfully renewed your ${formatVariationName(tvPlan)}",
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

  void _triggerVerifyMerchant() {
    if (selectedPlan != null && selectedPlan!.isNotEmpty &&
        _smartCardNumberController.text.length == 10) {
      verifyMerchant();
    }
  }

  void verifyMerchant() async {
    try {
      final response = await ref.read(verifyMerchantProvider.notifier).verifyMerchant(
          serviceId: selectedPlan ?? "",
          billersCode: _smartCardNumberController.text,
          type: _paymentTypeController.text.toLowerCase()
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
    final identifiers = ref.watch(identifierProvider);

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
                                _dropdownServiceProviderField(identifiers),

                                const SizedBox(height: 24),

                                _label("Payment Type"),
                                _dropdownPaymentTypeField(),

                                const SizedBox(height: 24),

                                _label("Smart Card Number"),
                                _inputField(
                                  controller: _smartCardNumberController,
                                  hint: "Enter smart card number",
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _triggerVerifyMerchant();
                                  },
                                ),
                                if (customerName.isNotEmpty || arrears.isNotEmpty)
                                  Row(
                                    children: [
                                      if (customerName.isNotEmpty)
                                        Text(
                                          customerName,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Colors.green
                                          ),
                                        ),
                                      if (arrears.isNotEmpty)
                                        Text(
                                          " $arrears",
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Colors.green
                                          ),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 24),

                                if (selectedPlan != null && selectedPlan!.isNotEmpty)
                                  ...[
                                    _label("Plan"),
                                    _dropdownPlanField(),
                                    const SizedBox(height: 24),
                                  ],

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
                                  controller: _amountController,
                                  hint: "Enter amount",
                                  keyboardType: TextInputType.number,
                                  isReadOnly: true
                                ),
                                const Spacer(),
                                RoundedButton(
                                    title: 'Continue',
                                    onPressed: () {
                                      if (_smartCardNumberController.text.isEmpty ||
                                          selectedPlan == null ||
                                          selectedPlan!.isEmpty ||
                                          _paymentTypeController.text.isEmpty ||
                                          _amountController.text.isEmpty) {
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
                                                  amount: _amountController.text,
                                                  items: [
                                                    ConfirmationItem(
                                                        label: "Service Provider:",
                                                        value: formatVariationName(selectedPlan ?? "")),
                                                    ConfirmationItem(
                                                        label: "Smart Card Number:",
                                                        value: _smartCardNumberController.text),
                                                    ConfirmationItem(
                                                        label: "Package",
                                                        value: formatVariationName(tvPlan ?? "")),
                                                    ConfirmationItem(
                                                        label: "Transaction fee:",
                                                        value: "₦0.00"),
                                                    ConfirmationItem(
                                                        label: "Description:",
                                                        value: "Cable TV"),
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
            "Cable TV",
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
    ValueChanged<String>? onChanged,
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
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownServiceProviderField(AsyncValue<List<IdentifierModel>> identifiers) {
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
              value: selectedPlan,
              hint: const Text(
                "Select Service Provider",
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
                if (value == null) return;

                final selectedIdentifier = variations.firstWhere(
                      (v) => v.serviceId == value,
                  orElse: () => variations.first,
                );

                setState(() {
                  selectedPlan = value;
                  tvPlan = null;
                  _amountController.clear();
                });

                ref
                    .read(variationProvider.notifier)
                    .loadServiceVariation(selectedIdentifier.serviceId);

                _triggerVerifyMerchant();
              },

            ),
          );
        },
      ),
    );
  }

  Widget _dropdownPaymentTypeField() {
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
          value: _paymentTypeController.text.isNotEmpty ? _paymentTypeController.text : null,
          hint: const Text(
            "Select Payment Type",
            style: TextStyle(color: Colors.white38),
          ),
          style: const TextStyle(color: Colors.white),
          items: category
              .map(
                (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() {
              _paymentTypeController.text = value ?? "";
            });
            _triggerVerifyMerchant();
          },
        ),
      ),
    );
  }

  Widget _dropdownPlanField() {
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
        error: (error, _) => const Center(
          child: Text(
            'Error loading plans',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (variation) {
          if (variation.isEmpty) {
            return const Center(
              child: Text(
                "No plans available",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF141019),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white54,
              ),
              value: tvPlan,
              hint: const Text(
                "Select Plan",
                style: TextStyle(color: Colors.white38),
              ),
              style: const TextStyle(color: Colors.white),
              items: variation.map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem<String>(
                  value: v.variationCode,
                  child: Text(v.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final selectedVariation = variation.firstWhere(
                        (v) => v.variationCode == value,
                  );
                  setState(() {
                    tvPlan = selectedVariation.variationCode;
                    _amountController.text = selectedVariation.variationAmount;
                  });
                  _triggerVerifyMerchant();
                }
              },
            ),
          );
        },
      ),
    );
  }
}