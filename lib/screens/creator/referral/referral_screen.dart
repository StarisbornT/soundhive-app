import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../../utils/app_constants.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  static const String id = '/referral';

  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  bool isLoading = true;
  bool isRedeeming = false;
  bool notACreator = false;

  String? referralCode;
  int totalReferrals = 0;
  int pointsBalance = 0;
  int pointsRedeemed = 0;
  int redeemableValueNgn = 0;
  String walletCurrency = 'USD';
  int minPointsToRedeem = 50;
  bool canRedeem = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchReferralInfo());
  }

  Future<void> fetchReferralInfo() async {
    setState(() => isLoading = true);
    try {
      final response = await ref.read(apiresponseProvider.notifier).getReferralInfo();

      if (response.status && response.data != null) {
        final data = response.data;
        setState(() {
          referralCode = data['referral_code'];
          totalReferrals = data['total_referrals'] ?? 0;
          pointsBalance = data['points_balance'] ?? 0;
          pointsRedeemed = data['points_redeemed'] ?? 0;
          redeemableValueNgn = data['redeemable_value_ngn'] ?? 0;
          walletCurrency = data['wallet_currency'] ?? 'USD';
          minPointsToRedeem = data['min_points_to_redeem'] ?? 50;
          canRedeem = data['can_redeem'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          showCustomAlert(
            context: context,
            isSuccess: false,
            title: 'Error',
            message: response.message.isNotEmpty ? response.message : 'Could not load referral info',
          );
        }
      }
    } on DioException catch (error) {
      setState(() => isLoading = false);
      if (error.response?.statusCode == 403) {
        setState(() => notACreator = true);
        return;
      }
      if (mounted) {
        String errorMessage = 'Could not load referral info. Please try again.';
        if (error.response?.data is Map && error.response?.data['message'] != null) {
          errorMessage = error.response!.data['message'];
        }
        showCustomAlert(context: context, isSuccess: false, title: 'Error', message: errorMessage);
      }
    } catch (error) {
      setState(() => isLoading = false);
      if (mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Could not load referral info. Please try again.',
        );
      }
    }
  }

  Future<void> redeemPoints() async {
    setState(() => isRedeeming = true);
    try {
      final response = await ref
          .read(apiresponseProvider.notifier)
          .redeemReferralPoints(context: context);

      if (response.status) {
        final creditAmount = response.data['credit_amount'];
        final currency = response.data['currency'];
        if (mounted) {
          showCustomAlert(
            context: context,
            isSuccess: true,
            title: 'Success',
            message: 'You redeemed $creditAmount $currency to your wallet!',
          );
        }
        await fetchReferralInfo();
      } else {
        if (mounted) {
          showCustomAlert(
            context: context,
            isSuccess: false,
            title: 'Error',
            message: response.message.isNotEmpty ? response.message : 'Redemption failed, please try again',
          );
        }
      }
    } on DioException catch (error) {
      String errorMessage = 'Redemption failed, please try again';
      if (error.response?.data is Map && error.response?.data['message'] != null) {
        errorMessage = error.response!.data['message'];
      }
      if (mounted) {
        showCustomAlert(context: context, isSuccess: false, title: 'Error', message: errorMessage);
      }
    } catch (error) {
      if (mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Redemption failed, please try again',
        );
      }
    } finally {
      if (mounted) setState(() => isRedeeming = false);
    }
  }

  void copyCode() {
    if (referralCode == null) return;
    Clipboard.setData(ClipboardData(text: referralCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }

  void shareCode() {
    if (referralCode == null) return;

    final storeLink = Platform.isIOS
        ? AppConstants.iosAppStoreUrl
        : AppConstants.androidPlayStoreUrl;

    SharePlus.instance.share(
      ShareParams(
        text: 'Join me on Cre8Hive! Use my referral code $referralCode when '
            'you sign up.\n\nDownload the app here: $storeLink',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        elevation: 0,
        title: Text(
          'Refer & Earn',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : notACreator
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Referrals are only available to creator accounts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchReferralInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share your code, earn 1 point per referral. $minPointsToRedeem points = redeemable wallet credit.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Referral code card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.PRIMARYCOLOR,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your referral code',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          referralCode ?? '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: copyCode,
                              icon: const Icon(Icons.copy, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: shareCode,
                              icon: const Icon(Icons.share, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(child: _statCard('Referrals', totalReferrals.toString())),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Points', pointsBalance.toString())),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statCard('Redeemed', pointsRedeemed.toString())),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Value (₦)', redeemableValueNgn.toString())),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (canRedeem && !isRedeeming) ? redeemPoints : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canRedeem ? AppColors.PRIMARYCOLOR : Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    canRedeem
                        ? 'Redeem to wallet ($walletCurrency)'
                        : 'Need $minPointsToRedeem points to redeem',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}