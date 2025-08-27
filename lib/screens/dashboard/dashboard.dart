import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:soundhive2/screens/creator/creator_dashboard.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
class DashboardScreen extends ConsumerWidget {
  static const String id = '/dashboard';

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: userState.when(
            data: (user) {
              if (user.user?.creator != null) {
                return  CreatorDashboard();
              }else {
                return NonCreatorDashboard();
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) {
              print("Error loading profile: $error");
              return Center(child: Text("Error loading profile: ${error.toString()}"));
            },
          ),
        ),
      ),
    );
  }

}
