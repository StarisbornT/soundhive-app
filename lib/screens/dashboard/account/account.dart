import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/dashboard/account/market_orders/my_orders.dart';
import '../../../model/user_model.dart';
import 'catalogue/catalogue.dart';

class AccountScreen extends ConsumerStatefulWidget {
  final User user;
  const AccountScreen({Key? key, required this.user}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D071A), // Dark background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0D071A),
        elevation: 0,
        title:  Row(
          children: [
            Image.asset('images/logo.png', height: 21),
            const SizedBox(width: 8),
            const Text(
              'Soundhive',
              style: TextStyle(
                fontFamily: 'Nohemi',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Account',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF715AFF),
                  child: Text(
                    widget.user.firstName![0],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.user.firstName!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                )
              ],
            ),
            const SizedBox(height: 24),
            _buildMenuItem(Icons.person_outline, 'Profile'),
            _buildMenuItem(Icons.queue_music_outlined, 'My Playlists'),
            _buildMenuItem(Icons.thumb_up_alt_outlined, 'Liked songs'),
            _buildMenuItem(Icons.mic_none_outlined, 'Karaoke recordings'),
            _buildMenuItem(Icons.bar_chart_outlined, 'Leaderboard'),
            _buildMenuItem(Icons.wifi_tethering_outlined, 'Streaming earnings', trailing: 'PREMIUM'),
            _buildMenuItem(Icons.receipt_long_outlined, 'Marketplace orders', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) =>  MyOrdersScreen(user: widget.user)));
            }),
            _buildMenuItem(Icons.settings_outlined, 'Settings'),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            const Text('CREATOR TOOLS', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 10),
            _buildMenuItem(Icons.mic_outlined, 'Artist Arena'),
            _buildMenuItem(Icons.library_add_outlined, 'Catalogue', onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) =>  CatalogueScreen()));
            }),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            _buildMenuItem(Icons.upgrade_outlined, 'Upgrade to premium'),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: trailing != null
          ? Text(trailing, style: const TextStyle(color: Colors.white60, fontSize: 12))
          : null,
      onTap: onTap,
    );
  }
}
