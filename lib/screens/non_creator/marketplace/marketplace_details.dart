import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/checkOfferProvider.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../components/creator_profile_widgets.dart';
import '../../../components/label_text.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveInvestmentProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/creatorProvider.dart';
import '../../../model/active_investment_model.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/creator_model.dart';
import '../../../model/creator_profile_models.dart';
import '../../../model/offerFromUserModel.dart';
import '../../../model/service_model.dart';
import '../../../model/user_model.dart';
import '../../../services/creator_profile_loader.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/no_phone_number_validator.dart';
import '../../dashboard/marketplace/markplace_recept.dart';
import '../../dashboard/verification_webview.dart';
import 'creator.dart';

final withdrawStateProvider = StateProvider<bool>((ref) => false);


class MarketplaceDetails extends ConsumerStatefulWidget {
  final ServiceItem service;
  final MemberCreatorResponse user;
  const MarketplaceDetails(
      {super.key, required this.service, required this.user});

  @override
  ConsumerState<MarketplaceDetails> createState() =>
      _MarketplaceDetailsScreenState();
}

class _MarketplaceDetailsScreenState extends ConsumerState<MarketplaceDetails>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  String? selectedPaymentOption;
  late List<DateTime> availabilityDates = [];
  double? _bookingAmount;

  // Terms of Service state
  bool _termsAccepted = false;
  bool _showTermsError = false;

  // Full creator profile (for the mandatory overview step)
  CreatorData? _creatorData;
  bool _creatorLoading = true;
  String? _creatorError;
  CreatorProfileExtras? _extras;
  late final TabController _profileTabController;

  static const _profileTabs = ['Overview', 'Portfolio', 'Experience', 'Skills', 'Reviews'];

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void initState() {
    super.initState();
    _profileTabController = TabController(length: _profileTabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkOfferProvider.notifier).checkOffer(widget.service.id);
      _fetchCreator();
    });
  }

  @override
  void dispose() {
    _profileTabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCreator() async {
    final creatorId = widget.service.user?.creator?.id;
    if (creatorId == null) {
      setState(() {
        _creatorLoading = false;
        _creatorError = 'Creator profile unavailable';
      });
      return;
    }

    try {
      final creator = await ref
          .read(creatorProvider.notifier)
          .getCreatorById(creatorId);
      if (!mounted) return;
      setState(() {
        _creatorData = creator;
        _extras = CreatorProfileExtras.fromCreator(creator);
        _creatorLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creatorError = 'Could not load creator profile';
        _creatorLoading = false;
      });
    }
  }

  void _showCounterOfferDialog(OfferFromUser offer, ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Counter Offer Received',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The creator has countered your offer:',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),

            // Original offer
            _buildCounterOfferRow(
              'Your Offer',
              ref.formatUserCurrency(offer.amount),
              theme,
            ),

            // Counter offer
            _buildCounterOfferRow(
              'Counter Offer',
              ref.formatUserCurrency(offer.counterAmount ?? '0'),
              theme,
            ),
            if (offer.counterMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Message: ${offer.counterMessage}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ),

            if (offer.counterExpiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Expires: ${_formatDate(offer.counterExpiresAt!)}',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _rejectCounterOffer(offer),
            child: Text(
              'Reject',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => _acceptCounterOffer(offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.BUTTONCOLOR,
            ),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterOfferRow(String label, String value, ThemeData theme,
      {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSecondary
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: isSecondary ? 12 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSecondary
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                  : theme.colorScheme.onSurface,
              fontSize: isSecondary ? 12 : 14,
              fontWeight: isSecondary ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCounterOffer(OfferFromUser offer) async {
    Navigator.pop(context);

    try {
      final response =
      await ref.read(apiresponseProvider.notifier).acceptCounterOffer(
        context: context,
        offerId: offer.id,
      );

      if (response.status) {
        await ref
            .read(checkOfferProvider.notifier)
            .checkOffer(widget.service.id);

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: 'Counter offer accepted successfully!',
        );
      }
    } catch (error) {
      _handleCounterOfferError(error);
    }
  }

  Future<void> _rejectCounterOffer(OfferFromUser offer) async {
    Navigator.pop(context);

    try {
      final response =
      await ref.read(apiresponseProvider.notifier).rejectCounterOffer(
        context: context,
        offerId: offer.id,
      );

      if (response.status) {
        await ref
            .read(checkOfferProvider.notifier)
            .checkOffer(widget.service.id);

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: 'Counter offer rejected.',
        );
      }
    } catch (error) {
      _handleCounterOfferError(error);
    }
  }

  void _handleCounterOfferError(dynamic error) {
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

    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: errorMessage,
    );
  }

  Widget _buildOfferButton(OfferFromUser? offer, ThemeData theme, bool isDark) {
    if (offer == null) {
      return OutlinedButton(
        onPressed: () => _showOfferBottomSheet(theme, isDark),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'Make an Offer',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      );
    }

    switch (offer.status) {
      case 'ACCEPTED':
        return OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Offer Accepted',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        );

      case 'REJECTED':
        return OutlinedButton(
          onPressed: () => _showOfferBottomSheet(theme, isDark),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Make New Offer',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        );

      case 'COUNTERED':
        return OutlinedButton(
          onPressed: () => _showCounterOfferDialog(offer, theme, isDark),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.yellow,
            side: const BorderSide(color: Colors.yellow),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Counter Offer',
            style: TextStyle(color: Colors.yellow),
          ),
        );

      case 'PENDING':
      default:
        return OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Offer Pending',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: _currentStep > 0
              ? () => setState(() => _currentStep--)
              : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        key: ValueKey(_currentStep),
        padding: const EdgeInsets.all(16.0),
        child: _buildStepContent(theme, isDark),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep(theme, isDark);
      case 1:
        if (_profileTabController.index != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _profileTabController.animateTo(0);
          });
        }
        return _buildCreatorOverviewStep(theme, isDark);
      case 2:
        return _buildConfirmationStep(theme, isDark);
      case 3:
        return _buildTermsStep(theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }
  Widget _buildCreatorOverviewStep(ThemeData theme, bool isDark) {
    if (_creatorLoading) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_creatorError != null || _creatorData == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(
              _creatorError ?? 'Something went wrong',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          const SizedBox(height: 20),
          RoundedButton(
            title: 'Continue',
            color: AppColors.BUTTONCOLOR,
            borderWidth: 0,
            borderRadius: 25.0,
            onPressed: () => setState(() => _currentStep++),
          ),
        ],
      );
    }

    final creator = _creatorData!;
    final extras = _extras!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About your creator',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Take a moment to review their work and reviews before booking.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        // Header: avatar, name, rating, trust badges
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.BUTTONCOLOR.withOpacity(0.6),
              backgroundImage: creator.user?.image != null
                  ? NetworkImage(creator.user!.image!)
                  : null,
              child: creator.user?.image == null
                  ? Text(
                (creator.user?.firstName.isNotEmpty ?? false)
                    ? creator.user!.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    creator.businessName ??
                        "${creator.user?.firstName ?? ''} ${creator.user?.lastName ?? ''}".trim(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${Utils.getOverallRating(creator).toStringAsFixed(1)} overall rating',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (extras.trustBadges.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TrustBadgeRow(badges: extras.trustBadges),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        TabBar(
          controller: _profileTabController,
          isScrollable: true,
          labelColor: AppColors.BUTTONCOLOR,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: AppColors.BUTTONCOLOR,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _profileTabs.map((t) => Tab(text: t)).toList(),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 420,
          child: TabBarView(
            controller: _profileTabController,
            children: [
              // Overview
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.bio ?? '',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: theme.colorScheme.onSurface.withOpacity(0.7), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          creator.location ?? '',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (extras.availability != null) ...[
                      const SizedBox(height: 16),
                      AvailabilityCard(info: extras.availability!),
                    ],
                  ],
                ),
              ),
              // Portfolio
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: PortfolioGrid(items: extras.portfolio, previewCount: 6),
              ),
              // Experience
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ExperienceTimeline(entries: extras.experience),
              ),
              // Skills
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SkillChips(skills: extras.skills),
              ),
              // Reviews
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingBreakdown(distribution: extras.ratingDistribution),
                    const SizedBox(height: 16),
                    if (creator.reviews.isEmpty)
                      Text(
                        'No reviews yet',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      )
                    else
                      ...creator.reviews.take(3).map((r) => ReviewItem(review: r)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Text('Back', style: TextStyle(color: theme.colorScheme.onSurface)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RoundedButton(
                title: 'Continue',
                color: AppColors.BUTTONCOLOR,
                borderWidth: 0,
                borderRadius: 25.0,
                onPressed: () => setState(() => _currentStep++),
              ),
            ),
          ],
        ),
      ],
    );
  }
  // ── Helper Badges for Delivery Days & Revisions ────────────────────
  Widget _buildServiceInfoBadge(IconData icon, String text, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.BUTTONCOLOR),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(ThemeData theme, bool isDark) {
    final offerState = ref.watch(checkOfferProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NetworkImageWithLoader(
          imageUrl: widget.service.coverImage,
        ),

        const SizedBox(height: 16),
        Text(
          widget.service.serviceName,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Dynamic price display
        _buildPriceDisplay(theme),

        const SizedBox(height: 8),
        // Delivery Days & Revisions Badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildServiceInfoBadge(
              Icons.schedule,
              '${widget.service.deliveryDays ?? 0} Days Delivery',
              theme,
              isDark,
            ),
            _buildServiceInfoBadge(
              Icons.sync,
              '${widget.service.revisions ?? 0} Revisions',
              theme,
              isDark,
            ),
          ],
        ),

        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            final creator = widget.service.user?.creator;

            if (creator != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatorProfileLoader(
                    creatorId: creator.id,
                  ),
                ),
              );
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.BUTTONCOLOR,
                backgroundImage: (widget.service.user?.image != null &&
                    widget.service.user!.image!.isNotEmpty)
                    ? NetworkImage(widget.service.user!.image!)
                    : null,
                child: (widget.service.user?.image == null ||
                    widget.service.user!.image!.isEmpty)
                    ? Text(
                  (
                      widget.service.user?.creator?.businessName?.isNotEmpty == true
                          ? widget.service.user!.creator!.businessName!
                          : widget.service.user?.firstName
                  )!
                      .trim()
                      .characters
                      .first
                      .toUpperCase(),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                widget.service.user?.creator?.businessName ??  "${widget.service.user?.firstName} ${widget.service.user?.lastName}",
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            Text(
              (widget.service.user?.creator != null)
                  ? Utils.getOverallRating(widget.service.user!.creator!).toStringAsFixed(1)
                  : "0.0",

              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 18),
            Text(
              widget.service.user?.creator?.location ?? '',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Description",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.serviceDescription ?? "",
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "About ${widget.service.user?.creator?.businessName?.isNotEmpty == true
              ? widget.service.user!.creator!.businessName
              : "${widget.service.user?.firstName ?? ''} ${widget.service.user?.lastName ?? ''}".trim()}",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 8),
        Text(
          widget.service.user?.creator?.bio ?? '',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        offerState.when(
          data: (data) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOfferButton(data.offer, theme, isDark),
                RoundedButton(
                  title: widget.user.user?.wallet == null
                      ? "Activate your wallet"
                      : 'Book',
                  onPressed: () {
                    if (widget.user.user?.wallet == null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WalletScreen(user: widget.user.user!),
                        ),
                      );
                    }else if (data.offer?.status == "PENDING") {
                      showCustomAlert(context: context, isSuccess: false, title: "Error", message: "Your Offer is on Pending");
                    }
                    else {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  },
                  color: AppColors.BUTTONCOLOR,
                  minWidth: 100,
                  borderWidth: 0,
                  borderRadius: 25.0,
                ),
              ],
            );
          },
          error: (err, stack) {
            debugPrint(err.toString());
            return Text(
              "Error loading offer",
              style: TextStyle(color: theme.colorScheme.error),
            );
          },
          loading: () => SizedBox(
            width: 120,
            child: Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDisplay(ThemeData theme) {
    return Consumer(
      builder: (context, ref, child) {
        final offerState = ref.watch(checkOfferProvider);

        return offerState.when(
          data: (data) {
            final hasAcceptedOffer = data.offer?.status == 'ACCEPTED';
            final offerAmount = data.offer?.amount;

            if (hasAcceptedOffer && offerAmount != null) {
              _bookingAmount = double.parse(offerAmount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original price with strikethrough
                  Row(
                    children: [
                      Text(
                        ref.formatUserCurrency(widget.service.convertedRate),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: theme.colorScheme.onSurface.withOpacity(0.5),
                          decorationThickness: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OFFER PRICE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Offer price
                  Text(
                    ref.formatUserCurrency(offerAmount),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            } else {
              _bookingAmount = double.tryParse(offerAmount ?? "") ?? 0.0;
              return Text(
                ref.formatUserCurrency(widget.service.convertedRate),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              );
            }
          },
          loading: () => Text(
            ref.formatUserCurrency(widget.service.convertedRate),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          error: (_, __) => Text(
            ref.formatUserCurrency(widget.service.convertedRate),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmationStep(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Booking',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),

        // Booking summary
        _buildBookingSummary(theme, isDark),

        const SizedBox(height: 20),
        PaymentMethodSelector(
          user: widget.user.user!,
          onSelected: (method) {
            debugPrint('Selected: $method');
            selectedPaymentOption = method;
          },
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        DateSelectionInput(
          onDatesSelected: (dates) {
            availabilityDates = dates;
            debugPrint(
                'Selected dates: ${dates.map((d) => DateFormat('dd/MM/yyyy').format(d)).join(', ')}');
          },
        ),
        const SizedBox(height: 150),
        RoundedButton(
          title: 'Continue',
          color: AppColors.BUTTONCOLOR,
          borderWidth: 0,
          borderRadius: 25.0,
          onPressed: () {
            setState(() {
              _currentStep++;
            });
          },
        )
      ],
    );
  }

  Widget _buildBookingSummary(ThemeData theme, bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        final offerState = ref.watch(checkOfferProvider);

        return offerState.when(
          data: (data) {
            final hasAcceptedOffer = data.offer?.status == 'ACCEPTED';
            final offerAmount = data.offer?.amount;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A191E)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Summary',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasAcceptedOffer && offerAmount != null) ...[
                    _buildSummaryRow(
                      'Original Price',
                      ref.formatUserCurrency(widget.service.convertedRate),
                      theme,
                    ),
                    _buildSummaryRow(
                      'Accepted Offer',
                      ref.formatUserCurrency(offerAmount),
                      theme,
                    ),
                    Divider(color: theme.dividerColor),
                    _buildSummaryRow(
                      'Total Amount',
                      ref.formatUserCurrency(offerAmount),
                      theme,
                      isTotal: true,
                    ),
                  ] else ...[
                    _buildSummaryRow(
                      'Total Amount',
                      ref.formatUserCurrency(widget.service.convertedRate),
                      theme,
                      isTotal: true,
                    ),
                  ],
                  if (hasAcceptedOffer) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4D2E).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFF4CAF50), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Booking at your accepted offer price',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => _buildLoadingSummary(theme, isDark),
          error: (_, __) => _buildLoadingSummary(theme, isDark),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSummary(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildTermsStep(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms of Service',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please review and accept our Terms of Service before proceeding with your booking.',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),

        // Terms content container
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A191E) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTermsSection(
                  theme,
                  '1. Booking Confirmation',
                  'By proceeding with this booking, you confirm that all information provided is accurate and complete. You understand that your booking is subject to the creator\'s availability and confirmation.',
                ),
                const SizedBox(height: 12),
                _buildTermsSection(
                  theme,
                  '2. Payment and Pricing',
                  'You agree to pay the total amount as displayed. All payments are final and non-refundable unless otherwise stated in the creator\'s cancellation policy.',
                ),
                const SizedBox(height: 12),
                _buildTermsSection(
                  theme,
                  '3. Cancellation Policy',
                  'Cancellations must be made at least 24 hours before the scheduled service date. Late cancellations may result in partial or full charges at the creator\'s discretion.',
                ),
                const SizedBox(height: 12),
                _buildTermsSection(
                  theme,
                  '4. Creator Liability',
                  'The platform acts as a facilitator between users and creators. We are not liable for the quality, safety, or legality of services provided. Please review the creator\'s profile and ratings before booking.',
                ),
                const SizedBox(height: 12),
                _buildTermsSection(
                  theme,
                  '5. User Conduct',
                  'You agree to treat creators with respect and professionalism. Any abusive, harassing, or inappropriate behavior may result in account suspension.',
                ),
                const SizedBox(height: 12),
                _buildTermsSection(
                  theme,
                  '6. Data Privacy',
                  'Your personal information will be handled in accordance with our Privacy Policy. We may share necessary information with the creator to facilitate the service.',
                ),
                const SizedBox(height: 12),
                _buildTermsSection(
                  theme,
                  '7. Dispute Resolution',
                  'Any disputes arising from this booking shall be resolved through our dispute resolution process. Both parties agree to engage in good faith negotiations before escalation.',
                ),
                const SizedBox(height: 12),
                _buildTermsSection(
                  theme,
                  '8. Modifications',
                  'These terms may be updated from time to time. The current version will always be available on our platform.',
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Last Updated: July 2026',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Terms acceptance checkbox
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _showTermsError
                ? Colors.red.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _showTermsError
                ? Border.all(color: Colors.red, width: 1.5)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _termsAccepted = !_termsAccepted;
                    _showTermsError = false;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: _termsAccepted
                        ? AppColors.BUTTONCOLOR
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _termsAccepted
                          ? AppColors.BUTTONCOLOR
                          : theme.colorScheme.onSurface.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: _termsAccepted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        children: const [
                           TextSpan(text: 'I have read and agree to the '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: AppColors.BUTTONCOLOR,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.BUTTONCOLOR,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showTermsError) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'You must agree to the Terms of Service to continue',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Navigation buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RoundedButton(
                title: 'Complete Booking',
                color: AppColors.BUTTONCOLOR,
                borderWidth: 0,
                borderRadius: 25.0,
                onPressed: () {
                  if (!_termsAccepted) {
                    setState(() {
                      _showTermsError = true;
                    });
                    return;
                  }
                  _submitBooking();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermsSection(ThemeData theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  void _showOfferBottomSheet(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return MakeOfferFormBottomSheet(
          theme: theme,
          isDark: isDark,
          onSubmit: (amount, message) {
            _makeAnOffer(amount, message);
          },
        );
      },
    );
  }

  void _submitBooking() async {
    if (availabilityDates.isEmpty || selectedPaymentOption == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please select a payment method and at least one start date.',
      );
      return;
    }

    try {
      final offerState = ref.read(checkOfferProvider);
      final hasAcceptedOffer = offerState.value?.offer?.status == 'ACCEPTED';
      final offerAmount = offerState.value?.offer?.amount;

      // Use accepted offer amount if available, otherwise use service rate
      final bookingAmount = hasAcceptedOffer ? double.parse(offerAmount!) : widget.service.convertedRate;

      final payload = {
        "service_id": widget.service.id,
        "date": availabilityDates
            .map((date) => DateFormat('yyyy-MM-dd').format(date))
            .toList(),
        "amount": bookingAmount,
      };

      // Add payment method to payload
      if (selectedPaymentOption != null) {
        payload["payment_method"] = selectedPaymentOption;
      }

      final response = await ref.read(apiresponseProvider.notifier).buyServices(
        context: context,
        payload: payload,
      );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();
        ref.read(getActiveInvestmentProvider.notifier).getActiveInvestments(
          pageSize: 10,
        );

        // Check if it's a Flutterwave payment (has payment_link)
        if (response.data != null && response.data['payment_link'] != null) {
          // Open Flutterwave webview for payment
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationWebView(
                url: response.data['payment_link'],
                title: 'Complete Payment',
              ),
            ),
          );

          if (result == 'success' && mounted) {
            // Refresh after successful payment
            await ref.read(userProvider.notifier).loadUserProfile();
            await ref.read(getActiveInvestmentProvider.notifier).getActiveInvestments(
              pageSize: 10,
            );

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Success(
                    title: 'Booking Confirmed',
                    subtitle: 'Your booking has been confirmed successfully!',
                    onButtonPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            }
          } else if (result != 'success' && mounted) {
            showCustomAlert(
              context: context,
              isSuccess: false,
              title: 'Payment Failed',
              message: 'Payment was not completed. Please try again.',
            );
          }
        } else {
          // Wallet payment - success
          final bookings = ActiveInvestment.fromMap(response.data);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Success(
                title: 'Booked Successfully',
                subtitle: 'You have successfully booked this service',
                onButtonPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketplaceReceiptScreen(
                        service: bookings,
                        paymentMethod: selectedPaymentOption ?? '',
                        price: bookingAmount.toString(),
                        availability: availabilityDates,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (error) {
      _handleBookingError(error);
    }
  }

  void _handleBookingError(dynamic error) {
    String errorMessage = 'An unexpected error occurred';

    debugPrint("Raw error: $error");

    if (error is DioException) {
      debugPrint("Dio error: ${error.response?.data}");
      debugPrint("Status code: ${error.response?.statusCode}");

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

  void _makeAnOffer(double amount, String? message) async {
    try {
      final payload = {
        "amount": amount,
        'service_id': widget.service.id,
        if (message != null) 'message': message,
      };

      final response = await ref.read(apiresponseProvider.notifier).makeOffer(
        context: context,
        payload: payload,
      );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();
        await ref.read(checkOfferProvider.notifier).checkOffer(widget.service.id);

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: "Offer Made Successfully",
        );
      }
    } catch (error) {
      _handleOfferError(error);
    }
  }

  void _handleOfferError(dynamic error) {
    String errorMessage = 'An unexpected error occurred';

    debugPrint("Raw error: $error");

    if (error is DioException) {
      debugPrint("Dio error: ${error.response?.data}");
      debugPrint("Status code: ${error.response?.statusCode}");

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
}

class MakeOfferFormBottomSheet extends ConsumerStatefulWidget {
  final ThemeData theme;
  final bool isDark;
  final Function(double amount, String? message) onSubmit;

  const MakeOfferFormBottomSheet({
    super.key,
    required this.theme,
    required this.isDark,
    required this.onSubmit,
  });

  @override
  ConsumerState<MakeOfferFormBottomSheet> createState() => _MakeOfferFormBottomSheetState();
}

class _MakeOfferFormBottomSheetState extends ConsumerState<MakeOfferFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Make an Offer',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 15),

            CurrencyInputField(
              label: "Offer Amount",
              controller: _amountController,
              currencySymbol: ref.userCurrencySymbol,
              onChanged: (value) {},
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }

                // 👈 Strip out commas before parsing
                final cleanValue = value.replaceAll(',', '').trim();

                if (double.tryParse(cleanValue) == null || double.parse(cleanValue) <= 0) {
                  return 'Please enter a valid active amount';
                }
                return null;
              },
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            LabeledTextField(
              label: 'Message / Note (Optional)',
              controller: _messageController,
              hintText: 'Add notes, timeline requests, or details...',
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              validator: NoPhoneNumberValidator.validate,
            ),
            const SizedBox(height: 25),

            // Submit Button
            RoundedButton(
              title: "Submit Offer",
              color: AppColors.BUTTONCOLOR,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // 👈 Clean commas here too so double.parse() doesn't crash the application
                  final cleanAmountText = _amountController.text.replaceAll(',', '').trim();
                  final double parsedAmount = double.parse(cleanAmountText);

                  final String? finalMessage = _messageController.text.trim().isEmpty
                      ? null
                      : _messageController.text.trim();

                  Navigator.pop(context);
                  widget.onSubmit(parsedAmount, finalMessage);
                }
              },
            ),

            // Adjusts container layout height when standard software keyboard rises
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
