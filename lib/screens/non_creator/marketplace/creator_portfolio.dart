import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../components/audio_player.dart';
import '../../../components/creator_profile_widgets.dart';
import '../../../components/rounded_button.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/creator_profile_models.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../utils/utils.dart';
import '../wallet/wallet.dart';
import 'creator.dart';
import 'marketplace_details.dart';

// ---------------------------------------------------------------------
// Service Detail page.
//
// Spec 6.1 — the same creator credibility block (verified work, videos,
// previous projects, client reviews, trust badges) that lives on the
// Creator Profile now also has to appear here, right before the user
// commits to an offer/booking — and this applies to ANY service listing
// (videographers, event production, etc.), not just artist profiles.
//
// ASSUMPTION: `MarketOrder` exposes a `creator` field (type `CreatorData`,
// nullable) pointing back to the person/business offering the service.
// If your model names this differently (e.g. `provider`, `owner`),
// rename `service.creator` below to match. If a service can be listed
// without an attached creator record, the trust block is simply skipped
// (see `_hasCreator`) rather than breaking the page.
// ---------------------------------------------------------------------

class CreatorPortfolio extends ConsumerStatefulWidget {
  final MarketOrder service;
  const CreatorPortfolio({super.key, required this.service});

  @override
  ConsumerState<CreatorPortfolio> createState() => _CreatorPortfolioState();
}

class _CreatorPortfolioState extends ConsumerState<CreatorPortfolio> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final service = widget.service;
    final user = ref.watch(userProvider);

    final creator = service.user?.creator;
    final hasCreator = creator != null;
    final extras = hasCreator ? CreatorProfileExtras.fromCreator(creator) : null;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image and Back Button
            SizedBox(
              height: size.height * 0.4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageWithLoader(imageUrl: service.serviceImage),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),

            // Title and Price Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    service.serviceName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
                  ),
                  Text(
                    ref.formatUserCurrency(service.convertedRate),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),

            // Service-level portfolio image (existing behavior, unchanged)
            const Padding(
              padding: EdgeInsets.only(left: 10, top: 16),
              child: Text(
                'Portfolio',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: size.width,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: NetworkImageWithLoader(imageUrl: service.coverImage),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.link ?? 'No Link',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.white),
                  ],
                ),
              ),
            ),

            if (service.serviceAudio != null) ...[
              AudioPlayerWidget(audioUrl: service.serviceAudio ?? ""),
            ],

            // --- NEW: creator credibility block, before Book/Offer ---
            // Surfaces trust badges + a portfolio strip + a link to the
            // full creator profile, so the decision to book is informed
            // by who the creator is, not just this one service listing.
            if (hasCreator) ...[
              CreatorTrustBlock(
                creatorName: creator.businessName ??
                    "${creator.user?.firstName ?? ''} ${creator.user?.lastName ?? ''}".trim(),
                creatorImage: creator.user?.image,
                badges: extras!.trustBadges,
                portfolioPreview: extras.portfolio,
                ratingDistribution: extras.ratingDistribution,
                onViewProfile: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreatorProfile(creator: creator)),
                  );
                },
              ),
              if (extras.ratingDistribution.totalReviews > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: RatingBreakdown(distribution: extras.ratingDistribution, compact: true),
                ),
              const SizedBox(height: 12),
            ],

            // Book Button
            RoundedButton(
              title: user.value?.user?.wallet == null ? "Activate your wallet" : 'Book',
              onPressed: () {
                final user = ref.watch(userProvider);
                if (user.value?.user?.wallet == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WalletScreen(user: user.value!.user!)),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketplaceDetails(user: user.value!, service: service),
                    ),
                  );
                }
              },
              color: const Color(0xFF4D3490),
              borderWidth: 0,
              borderRadius: 25.0,
            ),
          ],
        ),
      ),
    );
  }
}