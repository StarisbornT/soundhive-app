
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/creator/creator_dashboard.dart';
import 'package:soundhive2/screens/non_creator/non_creator_profile.dart';
import 'package:soundhive2/screens/non_creator/settings/settings.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/screens/non_creator/vest/vest.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';
import 'package:soundhive2/screens/notifications/notifications.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/notification_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/navigator_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/utils.dart';
import '../auth/login.dart';
import '../creator/profile/setup_screen.dart';
import '../onboarding/just_curious.dart';
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

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,

      /// APP BAR
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Consumer(
          builder: (context, ref, _) {
            final userData = ref.watch(userProvider).asData?.value;
            final user = userData?.user;

            return Row(
              children: [
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: CircleAvatar(
                    backgroundColor: colors.primary,
                    child: Text(
                      (user?.firstName.isNotEmpty == true)
                          ? user!.firstName[0]
                          : '?',
                      style: TextStyle(color: colors.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Welcome ${user?.firstName ?? ''},',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_sharp,
                  color: colors.onBackground,
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
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ).then((_) {
                ref
                    .read(notificationProvider.notifier)
                    .fetchUnreadCount();
              });
            },
          ),
        ],
      ),

      /// DRAWER
      drawer: Drawer(
        backgroundColor: colors.surface,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: userState.when(
            data: (userData) {
              final user = userData.user;

              return CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      DrawerHeader(
                        decoration: BoxDecoration(
                          color: colors.surface,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: colors.primary,
                              backgroundImage: user?.image != null
                                  ? NetworkImage(user!.image!)
                                  : null,
                              child: user?.image == null
                                  ? Text(
                                "${user?.firstName[0]}${user?.lastName[0]}",
                                style: TextStyle(
                                  color: colors.onPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${user?.firstName} ${user?.lastName}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 5),
                            if(user?.creator != null)
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  '${Utils.getOverallRating(user!.creator!)} overall rating',
                                  style: const TextStyle(
                                    color: Color(0xFFC5AFFF),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      _drawerItem(
                        context,
                        icon: 'images/transaction.png',
                        text: 'Home Screen',
                        onTap: () =>
                            Navigator.pushNamed(context, JustCurious.id),
                      ),

                      _drawerItem(
                        context,
                        icon: 'images/shop.png',
                        text: 'Cre8Hive - Marketplace',
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(bottomNavigationProvider.notifier)
                              .state = 0;
                        },
                      ),

                      _drawerItem(
                        context,
                        icon: 'images/profile.png',
                        text: 'Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NonCreatorProfile(
                                user: userData,
                              ),
                            ),
                          );
                        },
                      ),

                      _drawerItem(
                        context,
                        icon: 'images/music.png',
                        text: 'Soundhive - Stream Music',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Streaming(),
                            ),
                          );
                        },
                      ),

                      _drawerItem(
                        context,
                        icon: 'images/investment.png',
                        text: 'Cre8Vest',
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(bottomNavigationProvider.notifier)
                              .state = 2;
                        },
                      ),

                      _drawerItem(
                        context,
                        icon: 'images/wallet.png',
                        text: 'Cre8pay - Wallet',
                        onTap: () {
                          Navigator.pop(context);
                          ref
                              .read(bottomNavigationProvider.notifier)
                              .state = 1;
                        },
                      ),

                      _drawerItem(
                        context,
                        icon: 'images/settings.png',
                        text: 'Settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Settings(),
                            ),
                          );
                        },
                      ),
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
                              'Want to switch to\ncreator mode?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Click to switch',
                              style: TextStyle(color: Colors.white70),
                            ),
                              onTap: () { if(userData.user?.creator == null || userData.user?.creator!.active == false) { Navigator.push( context, MaterialPageRoute( builder: (context) => SetupScreen(user: userData,), ), ); }else { Navigator.pushReplacementNamed(context, CreatorDashboard.id); } }
                          ),
                        ),
                      ),
                    ]),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _drawerItem(
                          context,
                          icon: 'images/power.png',
                          text: 'Sign Out',
                          onTap: () async {
                            await ref
                                .read(apiresponseProvider.notifier)
                                .logout(context: context);
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Login.id,
                                  (_) => false,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
          ),
        ),
      ),

      /// BODY
      body: SafeArea(
        child: userState.when(
          data: (user) {
            final pages = [
              Marketplace(user: user),
              WalletScreen(user: user.user!),
              SoundhiveVestScreen(user: user),
              const Placeholder(),
            ];

            return RefreshIndicator(
              color: colors.primary,
              backgroundColor: colors.surface,
              onRefresh: () async {
                await ref
                    .read(userProvider.notifier)
                    .loadUserProfile();
              },
              child: pages[selectedIndex],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }

  /// DRAWER ITEM
  Widget _drawerItem(
      BuildContext context, {
        required String icon,
        required String text,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Image.asset(icon),
      title: Text(text),
      onTap: onTap,
    );
  }
}

