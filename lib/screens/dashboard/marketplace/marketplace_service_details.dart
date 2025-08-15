import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/service_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../account/market_orders/my_orders.dart';
final withdrawStateProvider = StateProvider<bool>((ref) => false);
class MarketPlaceServiceDetailsScreen extends ConsumerStatefulWidget {
  final dynamic services;
  final User user;
  const MarketPlaceServiceDetailsScreen({Key? key, required this.services, required this.user}) : super(key: key);

  @override
  _MarketPlaceDetailsScreenState createState() => _MarketPlaceDetailsScreenState();
}
class _MarketPlaceDetailsScreenState extends ConsumerState<MarketPlaceServiceDetailsScreen>  {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  int _currentStep = 0;
  int _selectedPaymentOption = 0;
  double? _investmentAmount;

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
        return _buildConfirmationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsStep() {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child:  ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (widget.services.imageUrl?.isNotEmpty ?? false)
                ? Image.network(
              widget.services.imageUrl!,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Utils.buildImagePlaceholder(),
            )
                : Utils.buildImagePlaceholder(),
          ),
        ),

        const SizedBox(height: 16),
        Text(
          widget.services.serviceType,
          style: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          Utils.formatCurrency(widget.services.price),
          style: const TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500, fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const CircleAvatar(
              radius: 15,
              backgroundImage: AssetImage('images/avatar.png'),
            ),
            const SizedBox(width: 8),
            Text(
              "${widget.services.seller!.firstName} ${widget.services.seller!.lastName}",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.person, color: Colors.grey, size: 18),
            Text(
              '${widget.services.purchasesCount} clients',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.star, color: Colors.yellow, size: 18),
            Text(
              '4.5 rating',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),


          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Available ${widget.services.workType} (${widget.services.availableToWork.join(', ')})',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),

        const SizedBox(height: 16),
         Text(
          "About ${widget.services.seller!.firstName}",
          style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.services.portfolio ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Center(
          child: RoundedButton(
            title: 'Book',
            onPressed: () {
              howtoPay(context);
            },
            color: const Color(0xFF4D3490),
            borderWidth: 0,
            borderRadius: 25.0,
          ),
        ),
        // const SizedBox(height: 20),
        // const Text(
        //   "Reviews (12,102)",
        //   style: TextStyle(
        //     color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
        //   ),
        // ),
        // const SizedBox(height: 10),
        // _buildReview("Susan Omotosho", "Good stuff, really makes sense"),
        // _buildReview("Susan Omotosho", "Good stuff, really makes sense"),
        // _buildReview("Susan Omotosho", "Good stuff, really makes sense"),
        // const SizedBox(height: 10),
        // Center(
        //   child: TextButton(
        //     onPressed: () {
        //       // Implement view more comments
        //     },
        //     child: const Text(
        //       "View more comments",
        //       style: TextStyle(color: Colors.white),
        //     ),
        //   ),
        // ),
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
            ),
            inputFormatters: [CurrencyInputFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter amount';
              final amount = double.tryParse(value.replaceAll(RegExp(r'[₦,]'), ''));
              if (amount == null) return 'Invalid amount';
              return null;
            },
          ),
          SizedBox(height: 50,),
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
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'How do you want to pay?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  // Instructional text
                  Text(
                    'Select from the options how you want to pay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 16),

                  // Payment Options
                  Column(
                    children: [
                      // Option 1: Soundhive Vest
                      GestureDetector(
                        onTap: () => setState(() => selectedOption = 0),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedOption == 0 ? Color(0xFF4D3490) : Colors.grey,
                            ),
                            color: Colors.black,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Soundhive Vest - ${Utils.formatCurrency('0')}',
                                        style: TextStyle(color: Colors.white),
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
                                activeColor: Color(0xFF4D3490),
                              ),
                            ],
                          ),

                        ),
                      ),
                      SizedBox(height: 12),

                      // Option 2: Paystack Checkout
                      GestureDetector(
                        onTap: () => setState(() => selectedOption = 1),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedOption == 1 ? Color(0xFF4D3490) : Colors.grey,
                            ),
                            color: Colors.black,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(Icons.payment, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Paystack checkout',
                                        style: TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<int>(
                                value: 1,
                                groupValue: selectedOption,
                                onChanged: (int? value) => setState(() => selectedOption = value!),
                                activeColor: Color(0xFF4D3490),
                              ),
                            ],
                          ),

                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

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
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Utils.confirmRow('Service', widget.services.serviceType),
              Utils.confirmRow('Price', Utils.formatCurrency(widget.services.price)),
              Utils.confirmRow('Payment Method', _selectedPaymentOption == 0 ? "Soundhive Vest" : "Paystack Checkout"),
            ],
          ),
        ),
        RoundedButton(title: 'Confirm & Pay',
          color: const Color(0xFF4D3490),
          borderWidth: 0,
          borderRadius: 25.0,
          onPressed: () {
            _submitInvestment();

          },
        )
      ],
    );
  }
  void _submitInvestment() async {

    // try {
    //   final response =  await ref.read(apiresponseProvider.notifier).buyServices(
    //     hiveServiceId: widget.services.hiveServiceId,
    //   );
    //   if(response.message == "Successful") {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => const Success(
    //           title: 'Service Purchased',
    //           subtitle: 'Your Service has been successfully added!',
    //         ),
    //       ),
    //     );
    //     await ref.read(userProvider.notifier).loadUserProfile();
    //     Navigator.push(context, MaterialPageRoute(builder: (_) =>  MyOrdersScreen(user: widget.user,)));
    //   } else {
    //     showCustomAlert(
    //       context: context,
    //       isSuccess: false,
    //       title: 'Error',
    //       message: response.message,
    //     );
    //   }
    //
    // } catch (error) {
    //   String errorMessage = 'An unexpected error occurred';
    //
    //   if (error is DioException) {
    //     if (error.response?.data != null) {
    //       try {
    //         final apiResponse = ApiResponseModel.fromJson(error.response?.data);
    //         errorMessage = apiResponse.message;
    //       } catch (e) {
    //         errorMessage = 'Failed to parse error message';
    //       }
    //     } else {
    //       errorMessage = error.message ?? 'Network error occurred';
    //     }
    //   }
    //
    //   print("Error: $errorMessage");
    //
    //   showCustomAlert(
    //     context: context,
    //     isSuccess: false,
    //     title: 'Error',
    //     message: errorMessage,
    //   );
    // }
  }

}

