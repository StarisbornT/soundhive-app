import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';

import '../../../components/pin_screen.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../lib/navigator_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/investment_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/utils.dart';
import '../wallet/wallet.dart';
final withdrawStateProvider = StateProvider<bool>((ref) => false);
class VestDetailsScreen extends ConsumerStatefulWidget {
  final Investment investment;
  final User user;
  const VestDetailsScreen({super.key, required this.investment, required this.user});

  @override
  _VestDetailsScreenState createState() => _VestDetailsScreenState();
}
class _VestDetailsScreenState extends ConsumerState<VestDetailsScreen>  {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  int _currentStep = 0;
  double? _investmentAmount;

  String _calculateMaturityDate(String createdAt, String durationMonths) {
    try {
      DateTime createdDate;

      // Handle different date formats
      if (createdAt.contains('T')) {
        createdDate = DateTime.parse(createdAt);
      } else {
        // If it's in format "YYYY-MM-DD HH:MM:SS"
        createdDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdAt);
      }

      final months = int.tryParse(durationMonths) ?? 0;

      // Calculate maturity date by adding months
      final maturityDate = DateTime(
        createdDate.year,
        createdDate.month + months,
        createdDate.day,
      );

      return DateFormat('MMM dd, yyyy').format(maturityDate);
    } catch (e) {
      // Fallback: show duration in months
      return 'In $durationMonths months';
    }
  }

  String _calculateExpectedRepayment(double amount, String roi, String durationMonths) {
    try {
      final roiPercent = double.tryParse(roi) ?? 0;
      final months = int.tryParse(durationMonths) ?? 0;

      if (roiPercent == 0 || months == 0) {
        return ref.formatUserCurrency(amount.toString());
      }

      // Calculate total interest (simple interest calculation)
      final totalInterest = amount * (roiPercent / 100) * (months / 12);

      // Calculate total repayment (principal + interest)
      final totalRepayment = amount + totalInterest;

      return ref.formatUserCurrency(totalRepayment.toString());
    } catch (e) {
      return ref.formatUserCurrency(amount.toString());
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _currentStep > 0
              ? () => setState(() => _currentStep--)
              : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildStepContent(),
      ),
    );
  }
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildAmountStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsStep() {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.investment.images.isNotEmpty)
          SizedBox(
            height: 220, // Increased height to accommodate peeking images
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.investment.images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.investment.images[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 50,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          widget.investment.investmentName,
          style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Min of ${ref.formatUserCurrency(widget.investment.convertedMinimumAmount) }',
          style: const TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500, fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 8),
        Text('ROI: ${widget.investment.roi}% in ${widget.investment.duration} months',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),

        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.star, color: Colors.yellow, size: 18),
            Text(
              '4.5 rating',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(width: 10),
            Icon(Icons.download, color: Colors.grey, size: 18),
            Text(
              '20k downloads',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "About Artist",
          style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.investment.description,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Center(
          child: RoundedButton(
            title: widget.user.wallet == null ?
            "Activate your wallet"
                :  'Invest',
            onPressed: () {
              if(widget.user.wallet == null) {
                Navigator.pop(context);
                ref.read(bottomNavigationProvider.notifier).state = 1;
              }
              else {
                setState(() => _currentStep++);
              }

            },
            color: const Color(0xFF4D3490),
            borderWidth: 0,
            borderRadius: 25.0,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Reviews (12,102)",
          style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        _buildReview("Susan Omotosho", "Good stuff, really makes sense"),
        _buildReview("Susan Omotosho", "Good stuff, really makes sense"),
        _buildReview("Susan Omotosho", "Good stuff, really makes sense"),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () {
              // Implement view more comments
            },
            child: const Text(
              "View more comments",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Investment Amount',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontFamily: 'Roboto', ),
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: Colors.white54, fontFamily: 'Roboto', ),
              border: OutlineInputBorder(),
            ),
              // inputFormatters: [CurrencyInputFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter amount';
              final amount = double.tryParse(value.replaceAll(RegExp(r'[₦,]'), ''));
              if (amount == null) return 'Invalid amount';
              final minAmount = widget.investment.convertedMinimumAmount;
              if (amount < minAmount) {
                return 'Minimum investment is ${ref.formatUserCurrency(widget.investment.convertedMinimumAmount)}';
              }
              return null;
            },
          ),
          const SizedBox(height: 50,),
          RoundedButton(
              title: 'Continue',
            color: const Color(0xFF4D3490),
            borderWidth: 0,
            borderRadius: 25.0,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _investmentAmount = double.parse(_amountController.text.replaceAll(RegExp(r'[₦,]'), ''));
                howtoPay(context);

              }
            },
          )

        ],
      ),
    );
  }

  void howtoPay(BuildContext context) {
    int selectedOption = 0; // Default selected option
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A191E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'How do you want to pay?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  // Instructional text
                  const Text(
                    'Select from the options how you want to pay.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // Payment Options
                  Column(
                    children: [
                      // Option 1: Soundhive Vest
                      GestureDetector(
                        onTap: () => setState(() => selectedOption = 0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedOption == 0 ? const Color(0xFF4D3490) : Colors.grey,
                            ),
                            color: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Soundhive Vest - ${ref.formatUserCurrency(widget.user.wallet?.balance)}',
                                        style: GoogleFonts.roboto(
                                          textStyle: const TextStyle(color: Colors.white)
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<int>(
                                value: 0,
                                groupValue: selectedOption,
                                onChanged: (int? value) => setState(() => selectedOption = value!),
                                activeColor: const Color(0xFF4D3490),
                              ),
                            ],
                          ),

                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Proceed Button
                  RoundedButton(
                    title: 'Proceed',
                    onPressed: () {
                      Navigator.pop(context);
                      this.setState(() => _currentStep++);
                    },
                    color: const Color(0xFF4D3490),
                    borderWidth: 0,
                    borderRadius: 25.0,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      children: [
        const Text(
          'Confirm Investment',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A191E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              confirmRow('Item', widget.investment.investmentName),
              confirmRow('Amount', ref.formatUserCurrency(_investmentAmount!)),
              confirmRow('Maturity Date', _calculateMaturityDate(widget.investment.createdAt, widget.investment.duration)),
              confirmRow('Interest', widget.investment.roi),
              confirmRow('Expected Return', _calculateExpectedRepayment(_investmentAmount!, widget.investment.roi, widget.investment.duration)),
            ],
          ),
        ),
        const SizedBox(height: 380,),
        RoundedButton(title: 'Make Payment',
          color: const Color(0xFF4D3490),
          borderWidth: 0,
          borderRadius: 25.0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PinAuthenticationScreen(
                  buttonName: 'Make Payment',
                  onPinEntered: (pin) {
                    _submitInvestment(pin);
                    // Handle PIN authentication logic here
                  },
                ),
              ),
            );
          },
        )
      ],
    );
  }

  Widget confirmRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFFB0B0B6))),
          Text(value, style: const TextStyle(fontSize: 14, fontFamily: 'Roboto', color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _submitInvestment(String pin) async {
    final maturityDate = _calculateMaturityDate(widget.investment.createdAt, widget.investment.duration);
    final expectedRepayment = _calculateExpectedRepayment(
      _investmentAmount!,
      widget.investment.roi,
      widget.investment.duration,
    );
    final cleanExpectedRepayment = expectedRepayment
        .toString()
        .replaceAll(RegExp(r'[NGN,]'), '');
    try {
      final response =  await ref.read(apiresponseProvider.notifier).joinInvestment(
        context: context,
        payload: {
          "vest_id": widget.investment.id,
          "amount": _investmentAmount,
          "expected_repayment": cleanExpectedRepayment,
          "maturity_date": maturityDate,
          "interest": widget.investment.roi,
          "pin": pin
        }
      );
      if(response.status) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Success(
              title: 'Investment Purchased',
              subtitle: 'Your Investment has been successfully added!',
            ),
          ),
        );
        await ref.read(userProvider.notifier).loadUserProfile();
        Navigator.pop(context);
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        showCustomAlert(
          context: context, // Use the stored context
          isSuccess: false,
          title: 'Error',
          message: response.message,
        );
      }

    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
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

      print("Error: $errorMessage");

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }


  Widget _buildReview(String name, String review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const CircleAvatar(radius: 15, backgroundImage: AssetImage('images/avatar.png')),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text(review, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

