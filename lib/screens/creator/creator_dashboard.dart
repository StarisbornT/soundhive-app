import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/screens/creator/artist_arena/aritst_arena.dart';
import 'package:soundhive2/screens/creator/artist_arena/artist_profile_screen.dart';
import 'package:soundhive2/screens/creator/chat_screen/chats.dart';
import 'package:soundhive2/screens/creator/profile/profile_screen.dart';
import 'package:soundhive2/screens/creator/services/services.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/notification_provider.dart';
import '../auth/login.dart';
import '../non_creator/wallet/transaction_history.dart';
import '../notifications/notifications.dart';
import 'creator_home.dart';
final creatorNavigationProvider = StateProvider<int>((ref) => 0);

class CreatorDashboard extends ConsumerWidget {
  static const String id = '/creator-dashboard';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  CreatorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final selectedIndex = ref.watch(creatorNavigationProvider);
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
          const SizedBox(width: 15),
          Consumer(
            builder: (context, ref, _) {
              final userData = ref.watch(userProvider).asData?.value;
              final user = userData?.user;
              return GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: CircleAvatar(
                  backgroundColor: AppColors.PRIMARYCOLOR,
                  child: Text(
                    (user?.firstName.isNotEmpty == true) ? user!.firstName[0] : '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 15),
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
                              backgroundColor: AppColors.PRIMARYCOLOR,
                              child: Text(
                                (user?.firstName.isNotEmpty == true)
                                    ? "${user?.firstName[0]}${user?.lastName[0]}"
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                      _buildDrawerItem(icon: 'images/profile.png', text: 'Profile', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>  ProfileScreen(user: userData),
                          ),
                        );
                      }),
                      _buildDrawerItem(icon: 'images/services.png', text: 'Services', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>   ServiceScreen(user: userData,),
                          ),
                        );
                      }),
                      _buildDrawerItem(icon: 'images/artist.png', text: 'Artist Arena', onTap: () {
                        if(user?.artist != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  ArtistProfileScreen(user: userData),
                            ),
                          );
                        }else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>  ArtistArena(user: userData),
                            ),
                          );
                        }

                      }),
                      _buildDrawerItem(icon: 'images/artist.png', text: 'Chats', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>   ChatListScreen(user: userData),
                          ),
                        );
                      }),
                      _buildDrawerItem(icon: 'images/transaction.png', text: 'Transactions History', onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>   TransactionHistory(user: userData,),
                          ),
                        );
                      }),
                      _buildDrawerItem(icon:'images/settings.png', text: 'Settings', onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) =>  const SoundhiveVest(),
                        //   ),
                        // );
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
                              'Want to switch to\nuser mode?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Click to switch',
                              style: TextStyle(color: Colors.white70),
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, NonCreatorDashboard.id);
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
              CreatorHome(user: user),
              const Placeholder(),
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
