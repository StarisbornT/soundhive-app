import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../components/audio_player.dart';
import '../../../components/rounded_button.dart';
import '../../../lib/dashboard_provider/user_provider.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/utils.dart';
import '../wallet/wallet.dart';
import 'marketplace_details.dart';

class CreatorPortfolio extends ConsumerStatefulWidget {
  final MarketOrder service;
  const CreatorPortfolio({super.key, required this.service});

  @override
  _CreatorPortfolioState createState() => _CreatorPortfolioState();

}

class _CreatorPortfolioState extends ConsumerState<CreatorPortfolio> {
  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final size = MediaQuery.of(context).size;

    final service= widget.service;
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
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
                  Image.network(
                    service.serviceImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.error)),
                  ),
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    Utils.formatCurrency(service.rate),
                    style: GoogleFonts.roboto(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      )
                    ),
                  ),
                ],
              ),
            ),

            // Portfolio Section
            const Padding(
              padding: EdgeInsets.only(left: 10, top: 16),
              child: Text(
                'Portfolio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  service.coverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error)),
                ),
              ),
            ),
          ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.link ?? 'No Link',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.open_in_new, color: Colors.white),
                  ],
                ),
              ),
            ),

            if(service.serviceAudio != null) ...[
              AudioPlayerWidget(audioUrl: service.serviceAudio ?? ""),
            ],



            // Book Button
            RoundedButton(
              title:  user.value?.user?.wallet == null ?
              "Activate your wallet"
                  :  'Book',
              onPressed: () {
                final user = ref.watch(userProvider);
                if(service.user?.wallet == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  WalletScreen(user: user.value!.user!,),
                    ),
                  );
                }
                else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  MarketplaceDetails(user: user.value!, service: service,),
                    ),
                  );
                }
              },
              color:const Color(0xFF4D3490),
              borderWidth: 0,
              borderRadius: 25.0,
            ),
          ],
        ),
      ),
    );
  }
}