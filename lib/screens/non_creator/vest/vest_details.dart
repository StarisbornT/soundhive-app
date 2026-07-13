import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import '../../../components/pin_screen.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/navigator_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/investment_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/utils.dart';

final withdrawStateProvider = StateProvider<bool>((ref) => false);

class VestDetailsScreen extends ConsumerStatefulWidget {
  final Investment investment;
  final User user;
  const VestDetailsScreen({super.key, required this.investment, required this.user});

  @override
  ConsumerState<VestDetailsScreen> createState() => _VestDetailsScreenState();
}

class _VestDetailsScreenState extends ConsumerState<VestDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  int _currentStep = 0;
  double? _investmentAmount;
  bool _isPlayingSnippet = false;

  String _calculateMaturityDate(String createdAt, String durationMonths) {
    try {
      DateTime createdDate;
      if (createdAt.contains('T')) {
        createdDate = DateTime.parse(createdAt);
      } else {
        createdDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdAt);
      }
      final months = int.tryParse(durationMonths) ?? 0;
      final maturityDate = DateTime(
        createdDate.year,
        createdDate.month + months,
        createdDate.day,
      );
      return DateFormat('MMM dd, yyyy').format(maturityDate);
    } catch (e) {
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
      final totalInterest = amount * (roiPercent / 100) * (months / 12);
      final totalRepayment = amount + totalInterest;
      return ref.formatUserCurrency(totalRepayment.toString());
    } catch (e) {
      return ref.formatUserCurrency(amount.toString());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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
    final bool isArtist = widget.investment.isArtistVest;
    final artistDetails = widget.investment.artistDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.investment.images.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.investment.images.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: MediaQuery.of(context).size.width * 0.8,
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
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
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
            ),
          ),
        const SizedBox(height: 16),

        // Investment Badging Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isArtist ? Colors.purple.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isArtist ? "🎵 ARTIST OPPORTUNITY" : "💼 GENERAL VEST",
                style: TextStyle(
                  color: isArtist ? Colors.purpleAccent : Colors.blueAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isArtist && artistDetails != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  artistDetails.projectStage,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          widget.investment.investmentName,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Min of ${ref.formatUserCurrency(widget.investment.convertedMinimumAmount)}',
          style: const TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ROI: ${widget.investment.roi}% in ${widget.investment.duration} months',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 16),

        // NEW: Audio Snippet Player Core Element
        if (isArtist && artistDetails?.previewAudioUrl != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A102F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlayingSnippet ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.purpleAccent,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPlayingSnippet = !_isPlayingSnippet;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artistDetails?.song?.title ?? 'Track Preview Snippet',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artistDetails?.song?.artist?.stageName ?? artistDetails?.song?.artist?.name ?? 'SoundHive Artist',
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // NEW: Funding Tracker Framework (For Artist Vests)
        if (isArtist && artistDetails != null) ...[
          const Text("Funding Progress", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Raised: ${ref.formatUserCurrency(artistDetails.totalRaised.toString())}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 12), // Adds a safe gap between the two metrics
              Expanded(
                child: Text(
                  'Target: ${ref.formatUserCurrency(artistDetails.fundingTarget.toString())}',
                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  textAlign: TextAlign.end, // Keeps target pinned neatly to the right edge
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: artistDetails.fundingProgress,
              backgroundColor: Colors.white10,
              color: Colors.purpleAccent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Revenue Split Framework Table Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSplitMetrics('Investor Pool', '${artistDetails.revenueSplitInvestor.toStringAsFixed(0)}%'),
                _buildSplitMetrics('Artist Return', '${artistDetails.revenueSplitArtist.toStringAsFixed(0)}%'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        Text(
          isArtist ? "About Project & Artist" : "About Investment",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          widget.investment.description,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Center(
          child: RoundedButton(
            title: widget.user.wallet == null ? "Activate your wallet" : 'Buy Opportunity',
            onPressed: () {
              if (widget.user.wallet == null) {
                Navigator.pop(context);
                ref.read(bottomNavigationProvider.notifier).state = 1;
              } else {
                setState(() => _currentStep++);
              }
            },
            color: const Color(0xFF4D3490),
            borderWidth: 0,
            borderRadius: 25.0,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSplitMetrics(String label, String rate) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(rate, style: const TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAmountStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Investment Amount', style: TextStyle(color: Colors.white, fontSize: 24)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontFamily: 'Roboto'),
            decoration: const InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(color: Colors.white54, fontFamily: 'Roboto'),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter amount';
              final amount = double.tryParse(value.replaceAll(RegExp(r'[₦,]'), ''));
              if (amount == null) return 'Invalid amount';
              final minAmount = widget.investment.convertedMinimumAmount;
              if (amount < minAmount) {
                return 'Minimum investment is ${ref.formatUserCurrency(widget.investment.convertedMinimumAmount.toString())}';
              }
              return null;
            },
          ),
          const SizedBox(height: 50),
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
    int selectedOption = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A191E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How do you want to pay?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Select from the options how you want to pay.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => selectedOption = 0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selectedOption == 0 ? const Color(0xFF4D3490) : Colors.grey),
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
                                    'Cre8Pay - ${ref.formatUserCurrency(widget.user.wallet?.balance.toString())}',
                                    style: GoogleFonts.roboto(textStyle: const TextStyle(color: Colors.white)),
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
                  const SizedBox(height: 24),
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
        const Text('Confirm Investment', style: TextStyle(color: Colors.white, fontSize: 24)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1A191E), borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              confirmRow('Item', widget.investment.investmentName),
              confirmRow('Type', widget.investment.isArtistVest ? "ARTIST VEST" : "GENERAL VEST"),
              confirmRow('Amount', ref.formatUserCurrency(_investmentAmount!.toString())),
              confirmRow('Maturity Date', _calculateMaturityDate(widget.investment.createdAt, widget.investment.duration)),
              confirmRow('Interest Rate', '${widget.investment.roi}%'),
              confirmRow('Expected Return', _calculateExpectedRepayment(_investmentAmount!, widget.investment.roi, widget.investment.duration)),
            ],
          ),
        ),
        const SizedBox(height: 100),
        RoundedButton(
          title: 'Make Payment',
          color: const Color(0xFF4D3490),
          borderWidth: 0,
          borderRadius: 25.0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PinAuthenticationScreen(
                  buttonName: 'Make Payment',
                  onPinEntered: (pin) => _submitInvestment(pin),
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
      padding: const EdgeInsets.only(bottom: 10),
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
    final expectedRepayment = _calculateExpectedRepayment(_investmentAmount!, widget.investment.roi, widget.investment.duration);
    final cleanExpectedRepayment = expectedRepayment.replaceAll(RegExp(r'[NGN₦,]'), '').trim();

    try {
      final response = await ref.read(apiresponseProvider.notifier).joinInvestment(
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
      if (response.status) {
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
        showCustomAlert(context: context, isSuccess: false, title: 'Error', message: response.message);
      }
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';
      if (error is DioException && error.response?.data != null) {
        try {
          final apiResponse = ApiResponseModel.fromJson(error.response?.data);
          errorMessage = apiResponse.message;
        } catch (_) {}
      }
      showCustomAlert(context: context, isSuccess: false, title: 'Error', message: errorMessage);
    }
  }
}