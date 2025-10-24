
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/creator/creator_dashboard.dart';
import 'package:soundhive2/screens/non_creator/non_creator_profile.dart';
import 'package:soundhive2/screens/non_creator/settings/settings.dart';
import 'package:soundhive2/screens/non_creator/streaming/preference.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/screens/non_creator/vest/vest.dart';
import 'package:soundhive2/screens/non_creator/wallet/transaction_history.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';
import 'package:soundhive2/screens/notifications/notifications.dart';

import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/notification_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/navigator_provider.dart';
import '../../utils/app_colors.dart';
import '../auth/login.dart';
import '../creator/profile/setup_screen.dart';
import 'marketplace/marketplace.dart';

class NonCreatorDashboard extends ConsumerWidget {
  static const String id = '/non-creator-dashboard';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  NonCreatorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final selectedIndex = ref.watch(bottomNavigationProvider);
    final unreadCount = ref.watch(notificationProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF0C051F),
        elevation: 0,
        title: Consumer(
          builder: (context, ref, _) {
            final userData = ref.watch(userProvider).asData?.value;
            final user = userData?.user;
            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Open the drawer when the avatar is tapped
                    _scaffoldKey.currentState?.openDrawer();
                  },
                  child: CircleAvatar(
                    backgroundColor: AppColors.BUTTONCOLOR,
                    child: Text(
                      (user?.firstName.isNotEmpty == true) ? user!.firstName[0] : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10,),
                Text(
                  'Welcome ${user?.firstName ?? ''},',
                  style: const TextStyle(
                    fontFamily: 'Nohemi',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.notifications_sharp,
                  color: Colors.white,
                  size: 24,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              ).then((_) {
                ref.read(notificationProvider.notifier).fetchUnreadCount();
              });
            },
          ),
        ],
      ),

      // ADDED: The Drawer widget for the sidebar
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A191E),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 900),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: userState.when(
            data: (userData) {
              final user = userData.user;
              return CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      DrawerHeader(
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A191E),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.BUTTONCOLOR,
                              backgroundImage: (user?.image != null)
                                  ? NetworkImage(user!.image!)
                                  : null,
                              child:(user?.image == null)
                                  ?  Text(
                                (user?.firstName.isNotEmpty == true)
                                    ? "${user?.firstName[0]}${user?.lastName[0]}"
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ): null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${user?.firstName} ${user?.lastName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 5),
                                Text(
                                  '4.5 overall rating',
                                  style: TextStyle(
                                    color: Color(0xFFC5AFFF),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildDrawerItem(icon: 'images/shop.png', text: 'Cre8Hive - Marketplace', onTap: () {
                        Navigator.pop(context);
                        ref.read(bottomNavigationProvider.notifier).state = 0;
                      }),
                      _buildDrawerItem(icon: 'images/profile.png', text: 'Profile', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>   NonCreatorProfile(user: userData,),
                          ),
                        );
                      }),
                      _buildDrawerItem(icon: 'images/music.png', text: 'Cre8Hive- Stream Music', onTap: () {
                        if(user?.interests == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  const PreferenceScreen(),
                            ),
                          );
                        }else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Streaming(
                              ),
                            ),
                          );
                        }

                      }),
                      _buildDrawerItem(icon: 'images/investment.png', text: 'Cre8Vest', onTap: () {
                        Navigator.pop(context);
                        ref.read(bottomNavigationProvider.notifier).state = 2;
                      }),
                      _buildDrawerItem(icon: 'images/wallet.png', text: 'Cre8pay - Wallet', onTap: () {
                        Navigator.pop(context);
                        ref.read(bottomNavigationProvider.notifier).state = 1;
                      }),
                      _buildDrawerItem(icon: 'images/transaction.png', text: 'Transactions History', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>   TransactionHistory(user: userData,),
                          ),
                        );
                      }),
                      _buildDrawerItem(icon: 'images/settings.png', text: 'Settings', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  const Settings(),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.PRIMARYCOLOR,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Image.asset('images/link.png'),
                            title: const Text(
                              'Want to switch to\n creator mode?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Click to switch',
                              style: TextStyle(color: Colors.white70),
                            ),
                            onTap: () {
                              if(userData.user?.creator == null || userData.user?.creator!.active == false) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SetupScreen(user: userData,),
                                  ),
                                );

                              }else {
                                Navigator.pushReplacementNamed(context, CreatorDashboard.id);
                              }
                            },
                          ),
                        ),
                      ),
                    ]),
                  ),
                  // Sign out button at the bottom
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDrawerItem(
                            icon: 'images/power.png',
                            text: 'Sign Out',
                            onTap: () async {
                              await ref.read(apiresponseProvider.notifier).logout(context: context);
                                Navigator.pushNamedAndRemoveUntil(context, Login.id, (route) => false);

                            },
                            textColor: Colors.white
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (error, stack) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.white))),
          ),
        ),
      ),

      // MAIN BODY
      body: SafeArea(
        child: userState.when(
          data: (user) {
            final List<Widget> pages = [
               Marketplace(user: user,),
              WalletScreen(user: user.user!,),
              SoundhiveVestScreen(user: user,),
              // SoundhiveVestScreen(user: user),
              // Marketplace(user: user),
              const Placeholder(),
            ];
            return RefreshIndicator(
              onRefresh: () async {
                try {
                  await ref.read(userProvider.notifier).loadUserProfile();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh: $e'),
                    ),
                  );
                }
              },
              color: Colors.white,
              backgroundColor: Colors.deepPurple,
              child: pages[selectedIndex],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            debugPrint("Error loading profile: $error");
            return Center(
              child: Text("Error loading profile: ${error.toString()}"),
            );
          },
        ),
      ),
    );
  }

  // Helper method to build the drawer list tiles
  Widget _buildDrawerItem({
    required String icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFA585F9),
    Color textColor = Colors.white,
  }) {
    return ListTile(
      leading: Image.asset(icon),
      title: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}